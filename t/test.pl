use Pwn::r2pipe;


my $r2pipe = Pwn::r2pipe->new("/bin/ls");
print $r2pipe->cmd("pi 10");
print $r2pipe->cmd("iI");
my $ds = $r2pipe->cmdj("ij");
print "Architecture: " . $ds->{bin}->{machine} . "\n";
$r2pipe->quit();

my $o = Pwn::r2pipe->new;
$o->open("/bin/ls");
print $o->cmd('iI');
$o->quit();
