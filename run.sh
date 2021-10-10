#!/bin/bash
function MergeResultFile(){
    inputFile=$1
    outputFile=$2
    echo "" >> $outputFile
    awk '
    BEGIN{
        lineHead="";
        outLine="";
    }
    {
        if( $1 != lineHead ){
            if( lineHead ~ /[0-9]+/ ){
                #// If lineHead is SNR, recalculate BLER
                printf " %.1f %.3f %d %d\n" ,arr[1], arr[3]/arr[4], arr[3], arr[4]
            }
            else{
                #// If lineHead is words, just print.
                print outLine;
            }
            lineHead=$1
        }

        if( $1 ~ /Source*/ ){
            #// if Source is not detected, store "Source:", else just append name of source file.
            if(!a[$1]++){
                outLine=$0;
            }
            else{
                outLine=outLine" "$2;
            }
        }
        else if( ($1 ~ /Config*/ || $1 ~ /Format*/) && !a[$1]++){
            #// if match to Config or Format, keep only one line.
            outLine=$0;
        }
        else if( $1 ~ /[0-9]+/ ){
            #// if match SNR
            #//     if first match, just store the line.
            #//     else add the number of ErrNum and TotalNum.
            if(!a[$1]++){
                # split with blank to store the elements in the line.
                split($0, arr, " ")
            }
            else{
                arr[3]+=$3; arr[4]+=$4
            }
        }
    }' $inputFile > tt.txt
    cat tt.txt > $outputFile && \rm -f tt.txt
    sed -i '/^\s*$/d' $outputFile && echo "" >> $outputFile
}
function PutWordsAhead(){
    file=$1
    word=$2
    sed -i '/^\s*$/d' $file && echo "" >> $file # Just leave the last line blank.
    # It is not output until the last line, that is blank line.(^\s*$) means blank line.
    # If match the $word, attach reserved content to the schema space, so word line will be the first.
    #    Then store to the reserved space.
    # Others lines, append to reserved space.
    sed -i "/${word}/{G;h;d};/^\s*$/{g;p};H;d" $file
    sed -i '/^\s*$/d' $file && echo "" >> $file # Just leave the last line blank.
}
###############################
# Main
oriFile="log.txt"
tmpFile="simParameterTmp.txt"
\cp -f $oriFile $tmpFile
echo "--------- output start -----------"
# remove tmpfiles.
\rm -f MD5*
\rm $tmpFile
declare -A md5Arr # Set associative array to store MD5 names.
# 1) Export files with the same configuration to the same file.
for i in `seq 0 3`; do # assume there are 4 folders and already know.
    configStr=`cat tc_$i/$oriFile | grep Config` # Get Config String.
    FormatStr=`cat tc_$i/$oriFile | grep Config` # Get Format String.
    # Generate MD5 string | use configStr and FormatStr as source | md5 coding | keep only digits and letter
    md5Str=`echo "$configStr$FormatStr" | md5sum | tr -d -c [0-9a-zA-Z]` 
    md5File="MD5$md5Str.txt" # Set md5 string as temp file name.
    cat tc_$i/$oriFile >> $md5File # Files of same config output to same file(md5 file).
    md5Arr[$md5Str]=1 # The assignment is arbitray, aiming to create member of the array.
done
# 2) Merge the data.
for m in ${!md5Arr[*]}; do # m is the md5 string, use ${!md5Arr[*]} to get these strings.
    md5File="MD5$m.txt" # temp file names.
    sed -i '/^\s*$/d' $md5File # remove the blank lines.
    sort -k1nr -k2n $md5File -o $md5File # sort the files with the first column. Second column is unnecessary.
    MergeResultFile $md5File $md5File # Merge Reuslt.
    # Put lines with certain words to first lines. So we get the order Config* \n Format* \n Source* \n Others
    PutWordsAhead $md5File "Source*" 
    PutWordsAhead $md5File "Format*"
    PutWordsAhead $md5File "Config*"
    cat $md5File >> $tmpFile # summarize all files.
done
\rm -f MD5* # remove temp files.
echo "--------- result start -----------"
cat $tmpFile
