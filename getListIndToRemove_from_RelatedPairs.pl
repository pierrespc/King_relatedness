#!/aplic/perl/bin/perl

use strict;
use warnings;
use Cwd;
my $inFile=shift or die "plink infile (bed format) ???\n";
my $KeepFile=shift or die "file for --keep option in plink??\n";
my $thresh=shift or die "kinship threshold???\n";
my $maf=shift or die "maf filter applied???\n";
my $outPref=shift or die "outFile Prefixe (with path if needed)\n";
print "remember:
an estimated kinship coefficient range:
>0.354 <=> duplicate/MZ twin
[0.177, 0.354] <=> 1st-degree
[0.0884, 0.177] <=> 2nd-degree
[0.0442, 0.0884] <=> 3rd degree\n";

my $kb=10000;
my $r2=0.2;
my $snps=1000;
print "by default we will LD prune data with KB=$kb, r2=$r2 and snps=$snps\n"; 

if( -e $outPref.".Pruned.RemoveKin".$thresh){
	print $outPref.".Pruned.RemoveKin".$thresh." already exists\n";
}else{
	####running King within Pop
	if( -e $outPref.".Pruned.Relationship.kin0"){
		print "kin0 already exists!\n";
	}else{
		print "let's generate kin0 file\n";
		if( -e $outPref.".Pruned.bed" && $outPref.".Pruned.fam"){
			print $outPref.".Pruned.bed already exists\n";
		}else{
			print "first let's generate bed file\n";
			system(" ~/src/plink1.9/plink --bfile ".$inFile." --keep ".$KeepFile." --maf ".$maf." --indep-pairwise ".$kb." ".$snps." ".$r2." --make-bed --out ".$outPref.".Pruned");
		}
	        system("/Users/pierrespc/Documents/PostDoc/scripts/Tools/King/Mac-king-single-thread -b ".$outPref.".Pruned.bed --kinship --prefix ".$outPref.".Pruned.Relationship");
		system("rm ".$outPref.".Pruned.bed");
#                system("rm ".$outPref.".Pruned.log");
#                system("rm ".$outPref.".Pruned.nosex");
                system("rm ".$outPref.".Pruned.bim");
	}
	if(! -e $outPref.".Pruned.Relationship.ListPerInd.kin".$thresh){
	       print "make listInd\n";

		open(KIN,$outPref.".Pruned.Relationship.kin0") || die ("can t read ".$outPref.".Pruned.Relationship.kin0\n");
		open(LIST,">".$outPref.".Pruned.Relationship.ListPerInd.kin".$thresh) || die ("can't write ".$outPref.".Pruned.Relationship.ListPerInd.kin".$thresh."\n");
		my @table=<KIN>;
		close(KIN);
		shift @table;
		my %listInds;
		foreach my $line (@table){
			chomp $line;
			my @splitted=split(/\s+/,$line);
			print $splitted[7]."\n";
			if( $splitted[7] > $thresh){				
				print $line."\n";
				my $ind1=$splitted[1];
				my $ind2=$splitted[3];
				print $splitted[7]." ".$ind1." ".$ind2."\n";
				if( ! exists $listInds{$ind1}){
					@{$listInds{$ind1}}=(1,$ind2);
				}else{
					${$listInds{$ind1}}[0] ++;
					push(@{$listInds{$ind1}},$ind2);	
				}
				if( ! exists $listInds{$ind2}){
					@{$listInds{$ind2}}=(1,$ind1);
				}else{
					${$listInds{$ind2}}[0] ++;
					push(@{$listInds{$ind2}},$ind1);	
				}
			}
		 }
		foreach my $key (keys %listInds){
			print LIST $key."\t".join("\t",@{$listInds{$key}})."\n";
		}
		close(LIST);
	}
	system("Rscript /Users/pierrespc/Documents/PostDoc/scripts/Tools/King//getListIndToRm.R  ".$outPref.".Pruned.Relationship.ListPerInd.kin".$thresh." ".$outPref.".Pruned.fam ".$outPref.".Pruned.RemoveKin".$thresh);
}

