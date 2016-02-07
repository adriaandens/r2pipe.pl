# Declare namespace
package Pwn::r2pipe;

# Declare dependencies
use strict;
use warnings;
use IO::Pty::Easy;
use JSON;

# Version
our $VERSION = 0.1;

sub new {
	my $class = shift;
	my %instance_values = ();

	return -1 if ! r2_exists(); # What are you even doing... :(

	# Create PTY
	my $r2pipe = IO::Pty::Easy->new;
	$instance_values{r2} = $r2pipe;

	# Check if file was given
	my $file;
	if(scalar(@_) > 0) { 
		$file = shift;
		$instance_values{file} = $file;
	}

	# If file is legit, then open the file with radare2
	if($file && -e $file && -f $file && -r $file) {
		$instance_values{r2}->spawn("r2 -q0 $file 2>/dev/null");
	}

	# Bless you.
	bless \%instance_values, $class;
}

sub r2_exists {
	`which r2`;
}

# Input: Filename to open in r2
sub open {
	my $self = shift;
	return -1 if scalar(@_) != 1; # No argument to open :(
	return -2 if $self->{file}; # We already have opened a file in r2?

	my $file = shift;
	# Check if filename exists, is a file and is readable
	if(! (-e $file && -f $file && -r $file) ) {
		return -3;
	}
	$self->{file} = $file;
	$self->{r2}->spawn("r2 -q0 $file 2>/dev/null");
}

sub cmd {
	my $self = shift;

	# Argument handling
	return -1 if scalar(@_) != 1; # No command to execute? :(
	return -2 if ! $self->{file}; # No file was loaded. :(
	my $command = shift;

	# Write the command...
	$self->{r2}->write($command . "\n");

	# Read the output...
	my $output = $self->{r2}->read();
	$output .= $self->{r2}->read(); # Don't ask me why...
	while(length($output) >= 8192) {
		# We probably don't have everything...
		$output .= $self->{r2}->read();
		print "Read $output...\n";
	}
	$output =~ s/^\x00//; # Once again, don't ask me why this happens

	return $output;
}

sub cmdj {
	my $self = shift;
	return -1 if scalar(@_) != 1; # We need an argument...
	return decode_json($self->cmd(shift));
}

sub quit {
	my $self = shift;
	$self->{r2}->close();
}

# Just for handiness sake. 
sub close {
	my $self = shift;
	$self->quit();
}

1;

__END__
=pod

=head1 NAME

Pwn::r2pipe - Interface with radare2

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Pwn::r2pipe;

    my $r2 = Pwn::r2pipe->new('/bin/ls');
    $r2->cmd('iI');
    $r2->cmdj('ij');
    $r2->quit();

    # Other stuff
    $r2 = Pwn::r2pipe->new;
    $r2->open('/bin/ls');
    $r2->cmd('pi 5');
    $r2->close(); # Same as quit()

=head1 DESCRIPTION

The r2pipe APIs are based on a single r2 primitive found behind r_core_cmd_str() which is a function that accepts a string parameter describing the r2 command to run and returns a string with the result.

The decision behind this design comes from a series of benchmarks with different libffi implementations and resulted that using the native API is more complex and slower than just using raw command strings and parsing the output.

As long as the output can be tricky to parse, it's recommended to use the JSON output and deserializing them into native language objects which results much more handy than handling and maintaining internal data structures and pointers.

Also, memory management results into a much simpler thing because you only have to care about freeing the resulting string.

=head1 METHODS

=head2 new($file)

The C<new> constructor initializes r2 and optionally loads a file into r2.

=head2 open($file)

Opens the file in radare2.

=head2 cmd($command)

Executes the command in radare2.

=head2 cmdj($command)

Executes the command in radare2 and JSON decodes the result into a Perl datastructure.

=head2 close

Closes the connection to radare2.

=head2 quit

Closes the connection to radare2. This is exactly the same as the close method.

=cut
