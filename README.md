# Pwn::r2pipe

Note: Of course, once I was almost ready with this code, I found that there is already an (official) implementation [here](https://github.com/radare/radare2-bindings/blob/master/r2pipe/perl/R2/Pipe.pm). But whatevah.

    use Pwn::r2pipe;

    my $r2 = Pwn::r2pipe->new('/bin/ls');
    my $result = $r2->cmd('iI');
    my $ds = $r2->cmdj('ij');
    print "Architecture: " . $ds->{bin}->{machine} . "\n";
    $r2->quit();

    # Other stuff
    $r2 = Pwn::r2pipe->new;
    $r2->open('/bin/ls');
    $r2->cmd('pi 5');
    $r2->close(); # Same as quit()

## Description

The r2pipe APIs are based on a single r2 primitive found behind `r_core_cmd_str()` which is a function that accepts a string parameter describing the r2 command to run and returns a string with the result.

The decision behind this design comes from a series of benchmarks with different libffi implementations and resulted that using the native API is more complex and slower than just using raw command strings and parsing the output.

As long as the output can be tricky to parse, it's recommended to use the JSON output and deserializing them into native language objects which results much more handy than handling and maintaining internal data structures and pointers.

Also, memory management results into a much simpler thing because you only have to care about freeing the resulting string.

## METHODS

### new($file)

The new constructor initializes r2 and optionally loads a file into r2.

### open($file)

Opens the file in radare2.

### cmd($command)

Executes the command in radare2.

### cmdj($command)

Executes the command in radare2 and JSON decodes the result into a Perl datastructure.

### close

Closes the connection to radare2.

### quit

Closes the connection to radare2. This is exactly the same as the close method.
