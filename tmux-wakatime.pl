#!/usr/bin/perl

use File::Basename;
use IO::File;
use Time::Stamp 'localstamp';

# timestamp
my $now = localstamp();

# check if we are in tmux
system("tmux ls > /dev/null 2>&1");
if ($? ne 0) {
	$ontmux = 0;
} else {
	$ontmux =1 ;
}

# username
my $username = $ENV{USERNAME};

# tmux display name
if ($ontmux) {
	my $tmux = `tmux display-message -p '#W'`;
	chomp($tmux);
}

# post or pre
my $when = $ARGV[0];

# path
my $path = $ARGV[1];

# command
my $command = $ARGV[2];

if ( $when eq "pre" ) {
    my $name;

    # if we are in a Git dir
    if ( ( $path =~ /Git/ ) || ( $path =~ /Project/ ) || $path =~ /Projects/) {
        if ( $path =~ /Git/ ) {
            if ( basename($path) ne "Git" ) {
                chdir($path);
                my $gitexec =
'git remote -v | head -n1 | awk \'{print $2}\' | sed -e \'s,.*:\(.*/\)\?,,\' -e \'s/\.git$//\'';
                $name = `$gitexec`;

                # chomp
                chomp($name);

                # trim
                $name =~ s/^\s+|\s+$//g;
		if ($ontmux) {
			my $tmuxexec = 'tmux rename-window "' . $name . '"';
			system("$tmuxexec &");
		} else {
			print "\033]0;" . $name . "\007";
		}
            }
        }
        if ( $path =~ /Project/ ) {
            my $projectname = basename($path);
            if ( $projectname ne "Project" ) {
		if ($ontmux) {
			my $tmuxexec = 'tmux rename-window "' . $projectname . '"';
			system("$tmuxexec &");
		} else {
			print "\033]0;" . $projectname . "\007";
		}
                my $log =
                  new IO::File ">>" . $path . "/." . $projectname . "-logfile";
                $log->print( "["
                      . $username . "] ["
                      . $now
                      . "] [start] "
                      . $command
                      . "\n" );
                $log->close();
            }
            $name = $projectname;

            # chomp
            chomp($name);

            # trim
            $name =~ s/^\s+|\s+$//g;
        }
    }
    else {
	if ($ontmux) {
		my $tmuxexec = 'tmux setw automatic-rename';
		system("$tmuxexec &");
	}
    }

    if ( $name eq '' ) {
        my $exec =
"wakatime --write --plugin \"tmux-wakatime/0.0.1\" --entity-type app --project \"Terminal\" --alternate-language fish --entity \"shell\"";

        system("$exec &");
    }
    else {
	$name =~ s/^\s+|\s+$//g;

        my $exec =
"wakatime --write --plugin \"tmux-wakatime/0.0.1\" --entity-type app --project \"$name\" --alternate-language fish --entity \"shell\"";

        system("$exec &");
    }

}

if ( $when eq "post" ) {
    my $gitname;

    # if we are in a Git dir
    if ( ( $path =~ /Git/ ) || ( $path =~ /Project/ ) ) {
        if ( $path =~ /Git/ ) {

# chdir($path);
# my $gitexec = 'git remote -v | head -n1 | awk \'{print $2}\' | sed -e \'s,.*:\(.*/\)\?,,\' -e \'s/\.git$//\'';
# $gitname = `$gitexec`;
# chomp($gitname);
# my $tmuxexec = 'tmux rename-window "' . $gitname . '"';
# system("$tmuxexec &");
        }
        if ( $path =~ /Project/ ) {
            my $projectname = basename($path);
            if ( $projectname ne "Project" ) {
                my $log =
                  new IO::File ">>" . $path . "/." . $projectname . "-logfile";
                $log->print( "["
                      . $username . "] ["
                      . $now
                      . "] [stop] "
                      . $command
                      . "\n" );
                $log->close();
            }
        }
    }
}
