#! /bin/bash

umask 0002
mkdir -p references && cd references

# List the available databases:
ls /groups/cbi/microbiome_database_final/ti/*.3.bt2* | sed 's|.3.bt2l\?$||' > cbi_databases.txt

# Manually edit cbi_databases.txt so that it contains only the databases we want. The first
# column contains the alias we use for the database and the second column is the prefix
# for the bt2 index files

# Create symlinks to database
cat cbi_databases.txt | while read l; do
    # Get the alias
    nn=$(awk '{print $1}' <<<$l)
    # Get the prefix
    prefix=$(awk '{print $2}' <<<$l)
    # For each bt2 index starting with prefix:
    for f2 in $prefix*.bt2*; do
        # Get the file extension, i.e. ".rev.1.bt2l"
        suffix=$(sed "s|$prefix||" <<<"$f2")
        ln -s $f2 $nn$suffix
    done
done

# Check that databases are intact
module load bowtie2
cat cbi_databases.txt | while read l; do
    nn=$(awk '{print $1}' <<<$l)
    echo "$nn  $(bowtie2-inspect -n $nn | wc -l)"
done

# Build the other databases
bowtie2-build ../allpathogen_ti.fa allpathogen
bowtie2-build ../allshrimpdata_ti.fa allshrimpdata

# Create files for target and filter databases
cut -f1 cbi_databases.txt > ../targets.txt
echo "allshrimpdata" > ../filter.txt

cd ..
