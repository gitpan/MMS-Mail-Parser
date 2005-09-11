package MMS::Mail::Parser;

use warnings;
use strict;
use IO::Wrap;
use IO::File;
use MIME::Parser;

use MMS::Mail::Message;
use MMS::Mail::Parser;

#  These are eval'd so the user doesn't have to install all Providers
eval {
  require MMS::Mail::Provider::UKVodafone;
};

=head1 NAME

MMS::Mail::Parser - A class for parsing MMS (or picture) messages.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This class takes an MMS message and parses it into two 'standard' formats (an MMS::Mail::Message and MMS::Mail::Message::Parsed) for further use.  It is intended to make parsing MMS messages network/provider agnostic such that a 'standard' object results from parsing, independant of the network/provider it was sent through.

=head2 Code usage example 

This example demonstrates the use of the two stage parse.  The first pass provides an MMS::Mail::Message object that is then passed through to the provider_parse message that attempts to determine the Network provider the message was sent through and extracts the relevant information and places it into an MMS::Mail::Message::Parsed object.

    use MMS::Mail::Parser;
    my $mms = MMS::Mail::Parser->new();
    my $message = $mms->parse(\*STDIN);
    if (defined($message)) {
      my $parsed = $mms->provider_parse;
      print $parsed->subject."\n";
    }

=head2 Examples of input

MMS::Mail::Parser has the same input methods as MIME::Parser.

    # Parse from a filehandle:
    $entity = $parser->parse(\*STDIN);

    # Parse an in-memory MIME message: 
    $entity = $parser->parse_data($message);

    # Parse a file based MIME message:
    $entity = $parser->parse_open("/some/file.msg");

    # Parse already-split input (as "deliver" would give it to you):
    $entity = $parser->parse_two("msg.head", "msg.body");

=head2 Examples of parser modification

MMS::Mail::Parser uses MIME::Parser as it's parsing engine.  The MMS::Mail::Parser class creates it's own MIME::Parser object if one is not passed in via the new or mime_parser methods.  There are a number of reasons for providing your own parser such as forcing all attachment storage to be done in memory than on disk (providing a speed increase to your application at the cost of memory usage).

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    my $mmsparser = new MMS::Mail::Parser;
    $mmsparser->mime_parser($parser);
    my $message = $mmsparser->parse(\*STDIN);
    if (defined($message)) {
      my $parsed = $mms->provider_parse;
    }

=head2 Examples of error handling

The parser contains an error stack and will ultimately return an undef value from any of the main parse methods if an error occurs.  The last error message can be retreived by calling last_error method.

    my $message = $mmsparser->parse(\*STDIN);
    unless (defined($message)) {
      print STDERR $mmsparser->last_error."\n";
      exit(0);
    }

=head2 Miscellaneous methods

There are a small set of miscellaneous methods available.  The output_dir method is provided so that a new MIME::Parser object does not have to be created to supply a separate storage directory for parsed attachments (however any attachments created as part of the process are removed when the message object is detroyed so the lack of specification of a storage location is not a huge issue ).

    # Provide debug ouput to STDERR
    $mmsparser->debug(1);

    # Set an output directory for MIME::Parser 
    $mmsparser->output_dir('/tmp');

    # Get/set an array reference to the error stack
    my $errors = $mmsparser->errors;

    # Get/set the MIME::Parser object used by MMS::Parser
    $mmsparser->mime_parser($parser);

=head2 Tutorial

A thorough tutorial can be accessed at http://www.robl.co.uk/redirects/articles/mmsmailparser/

=head1 METHODS

The following are the top-level methods of MMS::Mail::Parser object.

=head2 Constructor

=over

=item new()

Return a new MMS::Mail::Parser object. Valid attributes are:

=over

=item mime_parser MIME::Parser

Passed as an array reference, parser specifies the MIME::Parser object to use instead of MMS::Mail::Parser creating it's own.

=item debug INTEGER

Passed as an array reference, debug determines whether debuging information is outputted to standard error (default 0)	

=back

=back

=head2 Regular Methods

=over

=item parse INSTREAM

Returns an MMS::Mail::Message object by parsing the input stream INSTREAM

=item parse_data DATA 

Returns an MMS::Mail::Message object by parsing the in memory string DATA

=item parse_open EXPR

Returns an MMS::Mail::Message object by parsing the file specified in EXPR

=item parse_two HEADFILE, BODYFILE

Returns an MMS::Mail::Message object by parsing the header and body file specified in HEADFILE and BODYFILE

=item provider_parse MMS::MailMessage

Returns an MMS::Mail::Message::Parsed object by attempting to discover the network provider the message was sent through and parsing through the appropriate MMS::ProviderMailParser.  If an MMS::MailMessage object is supplied as an argument then the provider_parse method will parse the supplied MMS::Mail::Message object.  If a provider has been set via the provider method then that parser will be used by the provider_parse method instead of attempting to discover the network provider from the MMS::Mail::Message.

=item output_dir DIRECTORY

Returns the output_dir parameter used with the MIME::Parser object when invoked with no argument supplied.  When an argument is supplied it sets the output_dir used by the MIME::Parser to the value of the argument supplied.

=item mime_parser MIME::Parser

Returns the MIME::Parser object used by MMS::Mail::Parser (if created) when invoked with no argument supplied.  When an argument is supplied it sets the MIME::Parser object used by MMS::Mail::Parser to parse messages.

=item provider MMS::Mail::Provider

Returns an object for the currently set provider when invoked with no argument supplied.  When an argument is supplied it sets the provider to the supplied object.

=item errors 

Returns the error stack used by the MMS::Mail::Parser object as an array reference.

=item last_error

Returns the last error from the stack.

=item debug INTEGER

Returns a number indicating whether STDERR debugging output is active (1) or not (0).  When an argument is supplied it sets the debug property to that value.

=back

=head1 AUTHOR

Rob Lee, C<< <robl@robl.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mms-mail-parser@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MMS-Mail-Parser>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 NOTES

To quote the perl artistic license ('perldoc perlartistic') :

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
    WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES
    OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 ACKNOWLEDGEMENTS

As per usual this module is sprinkled with a little Deb magic.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Rob Lee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub new {
  my $type = shift;
  my $args = {@_};

  my $self = {};
  bless $self, $type;

  if (exists $args->{mime_parser}) {
    $self->{mime_parser} = $args->{mime_parser};
  } else {
    $self->{mime_parser} = undef;
  }

  if (exists $args->{debug}) {
    $self->{debug} = $args->{debug};
  } else {
    $self->{debug}=0;
  }

  $self->{message} = undef;
  $self->{errors} = [];

  return $self;
}

sub parse {

  my $self = shift;
  my $in = wraphandle(shift);

  print STDERR "Starting to parse\n" if ($self->debug);
  return $self->_parse($in);
}

sub parse_data {

  my $self = shift;
  my $in = shift;

  print STDERR "Starting to parse string\n" if ($self->debug);
  return $self->_parse($in);
}

sub parse_open {
    my $self = shift;
    my $opendata = shift;

    my $in = IO::File->new($opendata) || $self->_add_error("Could not open file - $opendata");
    return $self->_parse($in);
}

sub parse_two {
    my $self = shift;
    my $headfile = shift;
    my $bodyfile = shift;

    my @lines;
    foreach ($headfile, $bodyfile) {
        open IN, "<$_" || $self->_add_error("Could not open file - $_");
        push @lines, <IN>;
        close IN;
    }
    return $self->parse_data(\@lines);
}

sub _parse {

  my $self = shift;
  my $in = shift;

  unless (defined $self->mime_parser) {
    my $parser = new MIME::Parser;
    $parser->ignore_errors(1);
    $self->{mime_parser} = $parser;
  }

  if (defined $self->output_dir) {
    $self->{mime_parser}->output_dir($self->output_dir);
  }

  unless (defined $self->mime_parser) {
    $self->_add_error("Failed to create parser");
    return undef;
  }

  print STDERR "Created MIME::Parser\n" if ($self->debug);

  my $message = new MMS::Mail::Message;
  $self->{message} = $message;

  print STDERR "Created MMS::Mail::Message\n" if ($self->debug);

  my $parsed = eval { $self->{mime_parser}->parse($in) };
  if (defined $@ && $@) {
    $self->_add_error($@);
  }
  unless ($self->_recurse_message($parsed)) {
    $self->_add_error("Failed to parse message");
    return undef;
  }

  print STDERR "Parsed message\n" if ($self->debug);

  unless ($self->{message}->is_valid) {
    $self->_add_error("Parsed message is not valid");
    print STDERR "Parsed message is not valid\n" if ($self->debug);
    return undef;
  }

  print STDERR "Parsed message is valid\n" if ($self->debug);

  return $self->{message};

}

sub _recurse_message {

  my $self = shift;
  my $mime = shift;

  unless (defined($mime)) {
    $self->_add_error("No mime message supplied");
    return 0;
  }

  print STDERR "Parsing MIME Message\n" if ($self->debug);

  my $header = $mime->head;
  unless (defined($self->{message}->header_from)) {
    $self->{message}->header_datetime($header->get('Date'));
    $self->{message}->header_from($header->get('From'));
    $self->{message}->header_to($header->get('To'));
    $self->{message}->header_subject($header->get('Subject'));
    print STDERR "Parsed Headers\n" if ($self->debug);
  }

  my @multiparts;

  if($mime->parts == 0) {
    $self->{message}->body_text($mime->bodyhandle->as_string);
    print STDERR "No parts to MIME mail - grabbing header text\n" if ($self->debug);
    $mime->bodyhandle->purge;
  }

  print STDERR "Recursing through message parts\n" if ($self->debug);
  foreach my $part ($mime->parts) {
        my $bh = $part->bodyhandle;

        print STDERR "Message contains ".$part->mime_type."\n" if ($self->debug);

        if ($part->mime_type eq 'text/plain') {
          if (defined($self->{message}->body_text())) {
            $self->{message}->body_text(($self->{message}->body_text()) . $bh->as_string);
          } else {
            $self->{message}->body_text($bh->as_string);
          }
          $bh->purge;
          next;
        }

        if ($part->mime_type =~ /multipart/) {
          print STDERR "Adding multipart to stack for later processing\n" if ($self->debug);
          push @multiparts, $part;
          next;
        } else {
          print STDERR "Adding attachment to stack\n" if ($self->debug);
          $self->{message}->add_attachment($part);
        }

    }
    # Loop through multiparts
    print STDERR "Preparing to loop through multipart stack\n" if ($self->debug);
    foreach my $multi (@multiparts) {
      return $self->_recurse_message($multi);
    }

    return 1;

}

sub _decipher {

  my $self = shift;

  unless (defined($self->{message})) {
    $self->_add_error("No MMS mail message supplied");
    return undef;
  }

  if (defined($self->provider)) {
    my $message;
    #eval( 'require '.$self->provider.';'.'$message='.$self->provider.'::parse($self->{message})');
    $message = $self->provider->parse($self->{message});

    unless (defined $message) {
      print STDERR "Failed to parse message with custom Provider Object\n" if ($self->debug);
      if (defined($@) && $@) {
        $self->_add_error($@);
      }
    }

    return $message;
  }

  if ($self->{message}->header_from =~ /vodafone.co.uk$/) {
    print STDERR "UKVodafone message type detected\n" if ($self->debug);
    return MMS::Mail::Provider::UKVodafone::parse($self->{message});
  } else {
    print STDERR "No message type detected using base provider\n" if ($self->debug);
    return MMS::Mail::Provider::parse($self->{message});
  }

}

sub provider_parse {

  my $self = shift;
  my $message = shift;
  
  if (defined($message)) {
    $self->{message} = $message;
  }

  my $mms = $self->_decipher;

  unless (defined $mms) {
    $self->_add_error("Could not parse");
    print STDERR "Could not parse\n" if ($self->debug);
    return undef;
  }

  print STDERR "Returning MMS::Mail::Message::Parsed\n" if ($self->debug);

  return $mms;
}

sub debug {

  my $self = shift;
  my $debug = shift;

  unless (defined $debug) {
    if (exists($self->{debug})) {
      return $self->{debug};
    } else {
      return undef;
    }
  }
  chomp($debug);
  $self->{debug}=$debug;
}

sub mime_parser {

  my $self = shift;

  if (@_) { $self->{mime_parser} = shift }
  return $self->{mime_parser};

}

sub _add_error {

  my $self = shift;
  my $error = shift;

  unless (defined $error) {
    return 0;
  }
  push @{$self->{errors}}, $error;

  return 1;
}

sub errors {

  my $self = shift;
  return $self->{errors};

}

sub last_error {

  my $self = shift;

  if (@{$self->{errors}} > 0) {
    return ((pop @{$self->{errors}})."\n");
  } else {
    return undef;
  }

}

sub output_dir {

  my $self = shift;

  if (@_) { $self->{output} = shift }
  return $self->{output};

}

sub provider {

  my $self = shift;

  if (@_) { $self->{provider} = shift }
  return $self->{provider};

}

1; # End of MMS::Mail::Parser
