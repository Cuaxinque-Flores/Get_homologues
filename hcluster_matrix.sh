#!/usr/bin/env bash

# 2015 Pablo Vinuesa (1) and Bruno Contreras-Moreira (2):
# 1: http://www.ccg.unam.mx/~vinuesa (Center for Genomic Sciences, UNAM, Mexico)
# 2: http://www.eead.csic.es/compbio (Laboratory of Computational Biology, EEAD/CSIC, Spain)

#: AIM: generate a distance matrix out of a [pangenome|average_identity] matrix.tab file produced with
#       get_homologues.pl and accompanying scripts, such as compare_clusters.pl with options -t 0 -m.
#       This script applies R functions hclust() and heatmap.2() on such matrices.
#
#: OUTPUT: ph + svg|pdf output of hclust and heatmap2. 


progname=${0##*/} 
VERSION='0.6_24Dec17' # v0.6_124Dec17: remove the invariant (core-genome) and singleton columns from input table
         #v'0.5_14Oct17'; added options -A and -X to control the angle 
                      #                and character eXpansion factor of leaf labels
         #'0.4_7Sep17' # v0.4_7Sep17; added options -x <regex> to select specific rows (genomes) 
                     #                                       from the input pangenome_matrix_t0.tab
                     #                            -c <0|1> to print or not distances in heatmap cells
		     #                            -f <int> maximum number of decimals in matrix display (if -c 1)

         # v0.3_03Sep15 added ape's function write.tree() to generate a newick string from the hclust() object
         # v0.1_14Feb15, first version; generates hclust output in svg() and pdf(), formats,
		                  #  plus a heatmap in both formats

date_F=$(date +%F |sed 's/-/_/g')-
date_T=$(date +%T |sed 's/:/./g')
start_time="$date_F$date_T"

#---------------------------------------------------------------------------------#
#>>>>>>>>>>>>>>>>>>>>>>>>>>>> FUNCTION DEFINITIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
#---------------------------------------------------------------------------------#

function print_help()
{
    cat << HELP
    
    USAGE synopsis for: [$progname v.$VERSION]:
       $progname -i <string (name of matrix file)> [-d <distance> -a <algorithm> -o <format> ...]
    
    REQUIRED
       -i <string> name of matrix file     
       
    OPTIONAL:
       -a <string> algorithm/method for clustering 
             [ward.D|ward.D2|single|complete|average(=UPGMA)] [def $algorithm]
       -c <int> 1|0 to display or not the distace values      [def:$cell_note]
                    in the heatmap cells 
       -d <string> distance type [euclidean|manhattan|gower]  [def $distance]
       -f <int> maximum number of decimals in matrix display  [1,2; def:$decimals]
       -t <string> text for Main title                        [def:$text]
       -m <integer> margins_horizontal                        [def:$margin_hor]
       -v <integer> margins_vertical                          [def:$margin_vert]
       -o <string> output file format  [svg|pdf]              [def:$outformat]
       -p <integer> points for plotting device                [def:$points]    
       -H <integer> ouptupt device height                     [def:$height]    
       -W <integer> ouptupt device width                      [def:$width]     
       -N <flag> print Notes and exit                         [flag]

       -A <'integer,integer'> angle to rotate row,col labels  [def $angle]
       -X <float> leaf label character expansion factor       [def $charExp]
       

    Select genomes from input pangenome_matrix_t0.tab using regular expressions:
       -x <string> regex, like: 'Escherichia|Salmonella'      [def $regex]
       

    EXAMPLE:
      $progname -i pangenome_matrix_t0.tab -t "Pan-genome tree" -a ward.D2 -d euclidean -o pdf -x 'maltoph|genosp' -A 'NULL,45' -X 0.8

    AIM: compute a distance matrix from a pangenome_matrix.tab file produced after running 
         get_homologues.pl and compare_clusters.pl with options -t 0 -m .
         The pangenome_matrix.tab file processed by hclust(), and heatmap.2()
    
    OUTPUT: a newick file with extension .ph and svg|pdf output of hclust and heatmap.2 calls
     
    DEPENDENCIES:
         R packages: ape, cluster and gplots. Run $progname -N for installation instructions.

HELP

  check_dependencies

exit 0

}
#---------------------------------------------------------------------------

function print_notes()
{
   cat << NOTES
    
    NOTES: 

    $progname is a simple shell wrapper for the ape, cluster and gplots pacakges,
    calling functions to generate different distance matrices to compute distance 
    trees and ordered heatmaps with row dendrograms from the 
    pan_genome_matrix_t0.tab file generated by compare_clusters.pl 
    when using options -m and -t 0
   
    1) If the packages are not installed on your system, then proceed as follows:
    
    i) with root privileges, type the following into your shell console:
       sudo R
       > install.packages(c("ape", "gplots", "cluster"), dependencies=TRUE)
       > q()
       
       $ exit # quit root account
       $ R    # call R
       > library("gplots") # load the lib; do your stuff
       
    ii) without root privileges, intall the package into ~/lib/R as follows:
       $ mkdir -p ~/lib/R
       
       # set the R_LIBS environment variable before starting R as follows:
       $ export R_LIBS=~/lib/R     # bash syntax
       $ setenv R_LIBS=~/lib/R     # csh syntax
       # You can type the corresponding line into your .bashrc (or similar) configuration file
       # to make this options persistent
       
       # Call R from your terminal and type:
       > install.packages(c("ape", "gplots", "cluster"), dependencies=TRUE, lib="~/lib/R") 	
   
   iii) Once installed, you can read the documentation for packages and functions by typing the following into the R console:
      library("gplots")       # loads the lib into the environment
      help(package="gplots")  # read about the gplots package
      help(heatmap.2)         # read about the heatmap.2 function      
      help(svg)               # read about the svg function, which generates the svg ouput file     
      help(pdf)               # read about the pdf function, which generates the pdf ouput file     
      ...
     
   2. The pangenome_matrix ouput file will be automatically edited chagne PATH for Genome in cell 1,1
   
   3. Uses distance methods from the daisy() function from the cluster package.
   
      run ?daisy from within R for a detailed description of gower distances for categorical data
      
      http://rfunctions.blogspot.mx/2012/07/gowers-distance-modification.html
      http://pbil.univ-lyon1.fr/ade4/ade4-html/dist.binary.html
      https://stat.ethz.ch/R-manual/R-devel/library/cluster/html/daisy.html
      http://stats.stackexchange.com/questions/123624/gower-distance-with-r-functions-gower-dist-and-daisy
      http://cran.r-project.org/web/packages/StatMatch/StatMatch.pdf
      http://www.inside-r.org/packages/cran/StatMatch/docs/gower.dist
 
   4. For clustering see 
      http://www.statmethods.net/advstats/cluster.html for more details/options on hclust
 	    http://ecology.msu.montana.edu/labdsv/R/labs/lab13/lab13.html
     	http://www.instantr.com/2013/02/12/performing-a-cluster-analysis-in-r/

NOTES

   exit 0

}
#---------------------------------------------------------------------------

function check_dependencies()
{
    for prog in R
    do 
       bin=$(type -P $prog)
       if [ -z $bin ]; then
          echo
          echo "# ERROR: $prog not in place!"
          echo "# ... you will need to install \"$prog\" first or include it in \$PATH"
          echo "# ... exiting"
          exit 1
       fi
    done

    echo
    echo '# Run check_dependencies() ... looks good: R is installed.'
    echo   
}

#------------------------------------------------------------------------#
#------------------------------ GET OPTIONS -----------------------------#
#------------------------------------------------------------------------#
tab_file=
regex=

runmode=0
check_dep=0
cell_note=0

text="Pan-genome tree; "
width=17
height=15
points=15
margin_hor=20
margin_vert=21
outformat=svg
algorithm=ward.D2
distance=gower
decimals=2

charExp=1.0
angle='NULL,NULL'
#colTax=1

subset_matrix=0


# See bash cookbook 13.1 and 13.2
while getopts ':a:A:c:i:d:t:m:o:p:f:v:x:X:H:W:R:hND?:' OPTIONS
do
   case $OPTIONS in

   a)   algorithm=$OPTARG
        ;;
   A)   angle=$OPTARG
        ;;
   c)   cell_note=$OPTARG
        ;;
   d)   distance=$OPTARG
        ;;
   f)   decimals=$OPTARG
        ;;
   i)   tab_file=$OPTARG
        ;;
   m)   margin_hor=$OPTARG
        ;;	
   v)   margin_vert=$OPTARG
        ;;
   o)   outformat=$OPTARG
        ;;
   p)   points=$OPTARG
        ;;
   t)   text=$OPTARG
        ;;
   x)   regex=$OPTARG
        ;;
   X)   charExp=$OPTARG
        ;;
   C)   reorder_clusters=0
        ;;
   H)   height=$OPTARG
        ;;
   W)   width=$OPTARG
        ;;
   R)   runmode=$OPTARG
        ;;
   N)   print_notes
        ;;
   D)   DEBUG=$OPTARG
        ;;
   \:)   printf "argument missing from -%s option\n" $OPTARG
   	 print_help
     	 exit 2 
     	 ;;
   \?)   echo "need the following args: "
   	 print_help
         exit 3
	 ;;
    *)   echo "An  unexpected parsing error occurred"
         echo
         print_help
	 exit 4
	 ;;	 
   esac >&2   # print the ERROR MESSAGES to STDERR
done

shift $(($OPTIND - 1))

if [ -z $tab_file ]
then
       echo "# ERROR: no input tab file defined!"
       print_help
       exit 1    
fi

#if [ -z $runmode ]
#then
#       echo "# ERROR: no runmode defined!"
#       print_help
#       exit 1    
#fi

if [ -z $DEBUG ]
then
     DEBUG=0 
fi


if [ -z "$text" ]
then
    text=$(echo $tab_file)
fi

if [ ! -z "$regex" ]
then
    subset_matrix=1
fi



#-------------------#
#>>>>>> MAIN <<<<<<<#
#-------------------#

# 0) print run's parameter setup
wkdir=$(pwd)

cat << PARAMS

##############################################################################################
>>> $progname v$VERSION run started at $start_time
        working direcotry:$wkdir
        input tab_file:$tab_file | regex:$regex
	distance:$distance|dist_cutoff:$dist_cutoff|hclustering_meth:$algorithm|cell_note:$cell_note
        text:$text|margin_hor:$margin_hor|margin_vert:$margin_vert|points:$points
        width:$width|height:$height|outformat:$outformat
	angle:"$angle"|charExp:$charExp
##############################################################################################

PARAMS


# 1) prepare R's output file names
heatmap_outfile="hclust_${distance}-${algorithm}_${tab_file%.*}_heatmap.$outformat"
heatmap_outfile=${heatmap_outfile//\//_}
tree_file="hclust_${distance}-${algorithm}_${tab_file%.*}_tree.$outformat"
tree_file=${tree_file//\//_}
newick_file="hclust_${distance}-${algorithm}_${tab_file%.*}_tree.ph"
newick_file=${newick_file//\//_}

aRow=$(echo "$angle" | cut -d, -f1)
aCol=$(echo "$angle" | cut -d, -f2)

echo ">>> Plotting files $tree_file and $heatmap_outfile ..."
echo "     this will take some time, please be patient"
echo

# 2) replace path with "Genome" in first col of 1st row of source $tab_file (pangenome_matrix_t0.tab)
perl -pe 's/source\S+/Genome/' $tab_file > ${tab_file}ED

# 3) call R using a heredoc and write the resulting script to file 
R --no-save -q <<RCMD > ${progname%.*}_script_run_at_${start_time}.R
library("gplots")
library("cluster")
library("ape")

options(expressions = 100000) #https://stat.ethz.ch/pipermail/r-help/2004-January/044109.html

table <- read.table(file="${tab_file}ED", header=TRUE, sep="\t")

# remove the invariant (core-genome) columns
table <- table[sapply(table,  function(x) length(unique(x))>1)]

# remove the singleton columns (i.e., those with colSums > 1)
#   need to exclude column 1, which is not numeric
no_singletons <- table[, colSums(table[,-1]) > 1]

# add first (genome names) column back
table <- cbind(table[,1], no_singletons)
rm(no_singletons)

# filter rows with user-provided regex
if($subset_matrix > 0 ){
  include_list <- grep("$regex", table\$Genome)
   table <- table[include_list, ]
}

mat_dat <- data.matrix(table[,2:ncol(table)])

rnames <- table[,1]
rownames(mat_dat) <-rnames

my_dist <- daisy(mat_dat, metric="$distance", stand=FALSE)

write.table(as.matrix(my_dist), file="${distance}_dist_matrix.tab", row.names=TRUE, col.names=FALSE, sep="\t")

nwk_tree <- as.phylo(hclust(my_dist, method="$algorithm"), hang=-1, main="$algorithm clustering with $distance dist")
write.tree(phy=nwk_tree, file="$newick_file")

$outformat("$tree_file", width=$width, height=$height, pointsize=$pointsize)
plot(hclust(my_dist, method="$algorithm"), hang=-1, main="$algorithm clustering with $distance dist")
dev.off()
    
if($cell_note == 0){
   $outformat(file="$heatmap_outfile", width=$width, height=$height, pointsize=$pointsize)
   heatmap.2(as.matrix(my_dist), main="$text $distance dist.", notecol="black", density.info="none", trace="none", dendrogram="row", 
   margins=c($margin_vert,$margin_hor), lhei = c(1,5),
   cexRow=$charExp, cexCol=$charExp, 
   srtRow=$aRow, srtCol=$aCol)
   dev.off()
}

if($cell_note == 1){
   $outformat(file="$heatmap_outfile", width=$width, height=$height, pointsize=$pointsize)
   heatmap.2(as.matrix(my_dist), cellnote=round(as.matrix(my_dist),$decimals), main="$text $distance dist.", 
   notecol="black", density.info="none", trace="none", dendrogram="row", 
   margins=c($margin_vert,$margin_hor), lhei = c(1,5),
   cexRow=$charExp, cexCol=$charExp, 
   srtRow=$aRow, srtCol=$aCol)
   dev.off()
}    

RCMD


if [ -s $tree_file ]
then
     echo ">>> File $tree_file was generated"
else
     echo ">>> ERROR: File $tree_file was were NOT generated!"
fi


if [ -s ${distance}_dist_matrix.tab ]
then
     echo ">>> File ${distance}_dist_matrix.tab was generated"
else
     echo ">>> ERROR: File ${distance}_dist_matrix.tab was were NOT generated!"
fi

if [ -s $heatmap_outfile ] 
then
     echo ">>> File $heatmap_outfile was generated"
else
     echo ">>> ERROR: File $heatmap_outfile was were NOT generated!"
fi

if [ -s $newick_file ] 
then
     echo ">>> File $newick_file was generated"
else
     echo ">>> ERROR: File $newick_file was were NOT generated!"
fi
