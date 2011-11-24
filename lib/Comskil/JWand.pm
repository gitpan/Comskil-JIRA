# File: Comskil/JWand.pm
# Desc: A package that performs magic with remote JIRA services.

# #TODO Add in the sophisticated BEGIN/END package initialization blocks
# #TODO Add in the ability to log to a file.
# #TODO Run Perl Critic and Source code cleaner.


package Comskil::JWand;

use 5.006;
use strict;
use warnings;

our $VERSION    = "0.1";
our $COPYRIGHT  = "Copyright (c) 2011 Comskil, Inc.  All Rights Reserved Worldwide";
our $PRODUCT    = "Comskil::JWand";
our $USER_AGENT = "$PRODUCT\\$VERSION ($COPYRIGHT)";

=head1 NAME

Comskil::JWand - The great new Comskil::JWand!

=head1 VERSION

Version 0.1

=cut

use Carp;

use Data::Dumper; my $dd;

use File::Path qw(make_path remove_tree);
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);
use JIRA::Client;


sub _connect {
	my ($self,@args) = @_;

   return($self->{':jira_client'})
}



# Func: new(class_name [, options-hash] )
# Desc:
#
# Args: A hash containing key => value pairs to initialize the class.  The 
#       valid option keys are:
=head2 new()
=over 1
:username
:password
:baseurl
:
=cut

sub new {
    my $class = shift;
    my $options = shift;
    my $self = {
        ':jira_client' => undef		## #FIX Get rid of the leading colon on options
        ,':user_agent' => undef
        ,':max_results' => 13
        ,':max_issues' => undef
        ,':max_attachments' => undef
        ,':max_filesize' => undef
        ,':grab_thumbs' => 1
        ,'_server_info' => undef
        ,'_user_agent' => undef
        };
    @$self{ keys %{$options} } = values %{$options};
    bless($self,$class);

    if (! $self->{':jira_client'}) {
        $self->{':jira_client'} = JIRA::Client->new(
            $self->{':url'}
        	,$self->{':username'}
        	,$self->{':password'}
        	,( 'timeout' => 600)
        	);
    	$self->{'_server_info'} = eval { $self->{':jira_client'}->getServerInfo() };
    	croak sprintf("getServerInfo(): %s",$@) if $@;
    }
    
	return( $self->{':jira_client'} ? $self : undef);
}

sub jira_handle { 
	my $self = shift;
	return($self->{':jira_client'}); 
}

sub grabProjectKeys {
	my($self,$regx) = @_;
	
	
}

=over 4

=item B<grabAttachments> OUTPATH [, (<project-key>[,...])]]

asdfasdf

=cut

sub grabAttachments {
	my ($self,$path,@args) = @_;
	my ($cnt,$ua) = (undef,undef);
	
    ## Verify we are connected to a remote JIRA instance.

    return(undef) if (! $self->{':jira_client'});
	
	## If no project keys are specified find them all.
	
	## Make sure we have a UserAgent to access the remote JIRA instance to grab files.
	
	if (! $self->{'_user_agent'}) {
		$self->{':user_agent'} = $USER_AGENT if (! $self->{':user_agent'});
		my $rh = HTTP::Headers->new();
        $rh->authorization_basic($self->{':username'},$self->{':password'});
        $ua = $self->{'_user_agent'} = LWP::UserAgent->new( 
            agent => $USER_AGENT
            ,default_headers => $rh
            );
        ## $dd = Data::Dumper->new([$ua]); print $dd->Dump();
	}
   
	## Loop through the project keys grabbing all of the files on each iteration. 

    my $cnt_attach = 0;
    my $cnt_issues = 0;

    foreach my $pkey (@args) {

        my $ikey = "";            	
    	if ($pkey =~ m/(([A-Z]+)\-\d+)/) {
    		$pkey = $2;
    		$ikey = $1;
    	}

print "$pkey\n";
    	
        my $x = eval { $self->{':jira_client'}->getProjectByKey($pkey) };
        if ($@) {
        	carp sprintf("getProjectByKey('%s'): %s",$pkey,$@);
        	last;
        }
        
    	#### Iterate through each issue in the project.

        while (1) {
            my $jql = "project = $pkey " . (($ikey ne "") ? "and issueKey > $ikey " : "") . "order by issueKey asc";

#print "more issues....\n";

            my $ilist = eval { 
                $self->{':jira_client'}->getIssuesFromJqlSearch($jql,$self->{':max_results'}) 
                };
            if ($@) {
                carp sprintf("getIssuesFromJqlSearch('%s',%n): %s",$jql,$self->{':max_results'},$@);
                last;
            }
            last if (! @{$ilist});

            foreach my $issue (@$ilist) {
            	$cnt_issues++;
                $ikey = $issue->{'key'};
print "$ikey\n";                
                if (@{$issue->{'attachmentNames'}}) {
                    my $attach_list = eval { $self->{':jira_client'}->getAttachmentsFromIssue($ikey) };
                    croak sprintf("getAttachmentsFromIssue('%s'): %s",$ikey,$@) if $@;

                    ## $dd = Data::Dumper->new([$attach_list]); print $dd->Dump();
                        
                    my $fpth = "$path/$pkey/$ikey";
                    my $thmb = 0;
#print "$fpth\n";                    
                    foreach my $attach (@$attach_list) {

# Attachment Filespec := <jira-attachments>/<project-key>/<issue-key>/<attachment-id>
#            URL      := <base-url>/secure/attachment/<attachment-id>/<attachment-filename>
#                        https://request.siteworx.com/secure/attachment/17871/Wrong+FTP.jpg
#       '+' := <space_char>
# Thumbnail Filespec  := <jira-attachments>/<project-key>/<issue-key>/thumbs/_thumb_<attachment-id>.png
#           URL       := <base-url>/secure/thumbnail/<attachment-id>/_thumb_<attachment-id>.png
#                        https://request.siteworx.com/secure/thumbnail/17871/_thumb_17871.png
                    	
                    	next if (defined($self->{':max_filesize'}) && ($attach->{'filesize'} > $self->{':max_filesize'}));
                    	
                        my $furl = $self->{':url'}."/secure/attachment/".$attach->{'id'}."/".$attach->{'filename'};
                        my $fspc = $fpth."/".$attach->{'id'};
#print "$furl\n   ";
print "=> $fspc\n";
                                               
                    	make_path($fpth);
                        my $rh = $self->{'_user_agent'}->mirror($furl,$fspc);
                        $cnt_attach++ if (($rh->code() == HTTP_OK) || ($rh->code() == HTTP_NOT_MODIFIED));
                        
                        next if (! $self->{':grab_thumbs'});
                         
                        my $turl = $self->{':url'}."/secure/thumbnail/".$attach->{'id'}."/_thumb_".$attach->{'id'}.".png";
                        my $tspc = $fpth."/thumbs/_thumb_".$attach->{'id'}.".png";
#print "$turl\n   ";
print "=> $tspc\n";

                        make_path("$fpth/thumbs");
                        $rh = $self->{'_user_agent'}->mirror($turl,$tspc);
                        $thmb++ if (($rh->code() == HTTP_OK) || ($rh->code() == HTTP_NOT_MODIFIED));
                                            	
                        ## $dd = Data::Dumper->new([$attach]); print $dd->Dump();
                    }
                    remove_tree("$fpth/thumbs") if (! $thmb);
                    return($cnt_issues,$cnt_attach) if ((defined($self->{':max_attachments'}) &&
                                                         ($cnt_attach >= $self->{':max_attachments'})) ||
                                                        (defined($self->{':max_issues'}) &&
                                                         ($cnt_issues >= $self->{':max_issues'})));
                }
            }
        }
    }
    return($cnt_issues,$cnt_attach);
}

1;
__END__
### EOF

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Comskil::JWand;

    my $foo = Comskil::JWand->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Peter Shiner, C<< <pshiner at comskil.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-comskil-jwand at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Comskil-JWand>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Comskil::JWand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Comskil-JWand>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Comskil-JWand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Comskil-JWand>

=item * Search CPAN

L<http://search.cpan.org/dist/Comskil-JWand/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Peter Shiner.

This program is released under the following license: restrictive


=cut

1; # End of Comskil::JWand
