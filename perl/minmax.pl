#===============================================================================
# IDL-like minmax function:

sub minmax{

    my $special = shift;
    my (@numbers);

    @numbers = @_;

    my ($min, $max);

#     my $min = $numbers[0];
#     my $max = $numbers[0];

    foreach my $i (@numbers) {
    
      next if ($i < $special);

      (defined($min)) or $min = $i;
      (defined($max)) or $max = $i;

      if ($i > $max) {
          $max = $i;
      } elsif ($i < $min) {
          $min = $i;
      }

    }

    return ($min, $max);
    
}
#===============================================================================
# Perl modules that contain nothing but subroutines require this at the end:
1;
