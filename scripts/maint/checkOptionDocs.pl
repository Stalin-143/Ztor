#!/usr/bin/perl -w
use strict;

my %options = ();
my %descOptions = ();
my %torrcSampleOptions = ();
my %manPageOptions = ();

# Load the canonical list as actually accepted by Tor.
open(F, "/home/nexulean/Projects/tor/src/app/tor --list-torrc-options |") or die;
while (<F>) {
    next if m!\[notice\] Tor v0\.!;
    if (m!^([A-Za-z0-9_]+)!) {
        $options{$1} = 1;
    } else {
        print "Unrecognized output> ";
        print;
    }
}
close F;

# Load the contents of torrc.sample
sub loadTorrc {
    my ($fname, $options) = @_;
    local *F;
    open(F, "$fname") or die;
    while (<F>) {
        next if (m!##+!);
        if (m!#([A-Za-z0-9_]+)!) {
            $options->{$1} = 1;
        }
    }
    close F;
    0;
}

loadTorrc("/home/nexulean/Projects/tor/src/config/torrc.sample.in", \%torrcSampleOptions);

# Try to figure out what's in the man page.

my $considerNextLine = 0;
open(F, "/home/nexulean/Projects/tor/doc/man/tor.1.txt") or die;
while (<F>) {
    if (m!^(?:\[\[([A-za-z0-9_]+)\]\] *)?\*\*([A-Za-z0-9_]+)\*\*! && $considerNextLine) {
        $manPageOptions{$2} = 1;
        print "Missing an anchor: $2\n" unless (defined $1 or $2 eq 'tor');
        $considerNextLine = 1;
    } elsif (m!^\s*$! or
             m!^\s*\+\s*$! or
             m!^\s*//!) {
        $considerNextLine = 1;
    } else {
        $considerNextLine = 0;
    }
}
close F;

# Now, display differences:

sub subtractHashes {
    my ($s, $a, $b) = @_;
    my @lst = ();
    for my $k (keys %$a) {
        push @lst, $k unless (exists $b->{$k});
    }
    print "$s: ", join(' ', sort @lst), "\n\n";
    0;
}

# subtractHashes("No online docs", \%options, \%descOptions);
# subtractHashes("Orphaned online docs", \%descOptions, \%options);

subtractHashes("Orphaned in torrc.sample.in", \%torrcSampleOptions, \%options);

subtractHashes("Not in man page", \%options, \%manPageOptions);
subtractHashes("Orphaned in man page", \%manPageOptions, \%options);
