# File: jira-remote-merge.pl
# Desc: A program that examines a local JIRA backup file and then interogates
#       remote JIRA instances for data to be combined into a new backup file
#       in preparation of a project restore in order to import and integrate
#       the data from the remote system into a controlled instance.
#

# TODO Add in Perl documentations for the comman-line tool.
# TODO Flow down some of the options into the JWand object such as:
# TODO --verbose into JWand
# TODO --debug into JWand

use strict;
use warnings;
use Data::Dumper; my $dd;

use Getopt::Long; ## qw(:config no_ignore_case bundling no_auto_abbrev);
use Pod::Usage;
my $OPTS = ( );
my $PARSER = Getopt::Long::Parser->new( config => [ 'no_ignore_case', 'bundling', 'no_auto_abbrev' ]);
$PARSER->getoptions(
    '' => \$OPTS->{STDIO}
    ,'alittlehelp|?' => \$OPTS->{HELP}
    ,'help' => \$OPTS->{MANUAL}
    ,'verbose|v!' => \$OPTS->{VERBOSE}
    ,'quiet!' => sub { $OPTS->{VERBOSE} = 0; }
    ,'password|P=s' => \$OPTS->{PASSWORD}
    ,'username|user|U=s' => \$OPTS->{USERNAME}
    ,'url|u=s' => sub { my ($option,$url) = @_; $OPTS->{SOAP_URL} = $OPTS->{SITE_URL} = $url; }
    ,'site-url=s' => \$OPTS->{SITE_URL}
    ,'soap-url=s' => \$OPTS->{SOAP_URL}
    ,'project|projects|p=s' => sub { 
    	   my ($option,$str) = @_;
           $OPTS->{PROJECTS} = [ ] if (! $OPTS->{PROJECTS});
    	   my @tmp = split(/,/,join(',',@{$OPTS->{PROJECTS}},$str));
    	   $OPTS->{PROJECTS} =  \@tmp;
        }
    ,'define=s%' => sub {
           my ($option,$key,$val) = @_;
           $OPTS->{DEFINE} = ( ) if (! $OPTS->{DEFINE});
      	   $OPTS->{DEFINE}->{$key} = $val;
        }
    ,'max-filesize=i' => \$OPTS->{MAX_FILESIZE}
    ,'max-results|max-result|max_resultcount=i' => \$OPTS->{MAX_RESULTS}
    ,'max-issues|issues=i' => \$OPTS->{MAX_ISSUES}
    ,'max-attachments=i' => \$OPTS->{MAX_ATTACHMENTS}
    ,'attachments' => sub { $OPTS->{MAX_ATTACHMENTS} = 0; }
    ,'timeout|t=i' => \$OPTS->{TIMEOUT}
    ,'infile|in|i=s' => \$OPTS->{INFILE}
    ,'outfile|out|o=s' => \$OPTS->{OUTFILE}
    ,'validate|V' => \$OPTS->{VALIDATE}
    ,'loglevel|l=i' => \$OPTS->{LOGLEVEL}
    ,'logfile=s' => \$OPTS->{LOGFILE}
    ,'log+' => \$OPTS->{LOGLEVEL}
    ,'debug+' => \$OPTS->{DEBUG}
    ) or pod2usage(2);
if (defined($OPTS->{DEBUG}) && ($OPTS->{DEBUG} >= 2)) {
     $dd = Data::Dumper->new([$PARSER]); 
     print '[$PARSER]'," := (\n",$dd->Dump(),")\n"; 
}
if ($OPTS->{DEBUG}) { $dd = Data::Dumper->new([$OPTS]); print '[$OPTS]'," := (\n",$dd->Dump(),")\n"; }
if ($OPTS->{DEBUG}) { $dd = Data::Dumper->new([@ARGV]); print '[@ARGV]'," := (\n",$dd->Dump(),")\n"; }
pod2usage(1) if ($OPTS->{HELP});
pod2usage('-exitstatus' => 0, '-verbose' => 2) if ($OPTS->{MANUAL});

###
### START OF THE GUTS  
###

use Comskil::JWand;

#my $wand_cfg = ( );
#$wand_cfg->{:}
my $wand = Comskil::JWand->new( { 
    ':username' => $OPTS->{USERNAME}
    ,':password' => $OPTS->{PASSWORD}
    ,':url' => $OPTS->{SOAP_URL}
#    ,':max_filesize' => 49999
    } );


$wand->grabAttachments('./attachments', @{$OPTS->{PROJECTS}}); 



## $dd = Data::Dumper->new([$wand]); print $dd->Dump();

__END__   ### End of Program Source
=head1 NAME

jira-remote-merge.pl - A tool to integrate a remote JIRA instance with a local XML backup file.

=head1 SYNOPSIS
 
jira-remote-merge.pl [<option> [...]] [<arg> [...]]

=head1 OPTIONS

=over 15

=item -?,--help

print short and long help messages 

=item --verbose

show run-time progress information

=item -U,--url

URL for accessing SOAP functions of the JIRA instance

=item -U,--username

=item -P,--password

username and password used to authenticate to the remote server
 
=item -i,--infile

=item -o,--outfile

=item -V,--validate

=back
 
=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

There can be several paragraphs.

Each with a line in between.

=head2 Additional Options

=over 15

=item --debug

Display debug information about program structures and status as it is running.
This is useful to make sure the program is parsing and acting on the data in ways you
expect.

=item --loglevel

=item --logfile

=item -t,--timeout

=item -p,--project

=item -d,--define

=item --soap-url

=item --site-url

=item -q,--quiet

=item --max_filesize

=item --max_requests

=item --max_attachments

=item --max_issues

=back

=cut
### EOF