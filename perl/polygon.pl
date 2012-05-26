use Math::Trig;
use Data::Dumper;

$PI = 4*atan(1);

sub is_in_polygon{

### subroutine is_in_polygon,   Oliver Czoske, 12.4.2000
###      ---> check whether point ($x, $y) is inside polygon defined by 
###           (\@px, \@py) (first and last vertex are identical)
###      call: $isin = is_in_polygon($x, $y, $N, \@px, \@py);
###      return:    1  point is inside polygon
###                 0  point is outside polygon
###                 0.5 point is on an edge (or vertex) of polygon 
###      algorithm: sum angles between lines from point to adjacent vertices;
###                 if point is outside polygon these angles sum to zero

    my ($x, $y, $N, $px, $py) = @_;
    my ($i);
    my $phi = 0;
    my ($dphi, $dx1, $dx2, $dy1, $dy2, $l1, $l2);
    my ($sinphi, $cosphi);

    
    for ($i = 0; $i < $N-1; $i++){
	$dx1 = $$px[$i] - $x;
	$dy1 = $$py[$i] - $y;
	$dx2 = $$px[$i+1] - $x;
	$dy2 = $$py[$i+1] - $y;
	$l1 = sqrt($dx1*$dx1+$dy1*$dy1);
	$l2 = sqrt($dx2*$dx2+$dy2*$dy2);

	if ($l1 == 0 or $l2 == 0){
	    return 0.5;
	}
	
	$sinphi = ($dx1*$dy2-$dy1*$dx2)/($l1*$l2);
	$cosphi = ($dx1*$dx2+$dy1*$dy2)/($l1*$l2);
	
	if (abs($sinphi) < 0.001 and abs(1+$cosphi) < 0.001){
	    return 0.5;
	}

	$dphi = asin($sinphi);
	
	if ($sinphi < 0 and $cosphi < 0){
	    $dphi = - $PI - $dphi; 
	} elsif ($sinphi > 0 and $cosphi < 0){
	    $dphi = $PI - $dphi;
	}
	
	$phi += $dphi;
    }
    
    if (abs($phi) < 1e-3){
	return 0;   # outside polygon
    } else {
	return 1;   # inside polygon
    }
}
