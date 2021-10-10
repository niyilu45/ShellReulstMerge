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
                printf " %.1f %.3f %d %d\n" ,arr[1], arr[3]/arr[4], arr[3], arr[4]
            }
            else{
                print outLine;
            }
            lineHead=$1
        }

        if( $1 ~ /Source*/ ){
            if(!a[$1]++){
                outLine=$0;
            }
            else{
                outLine=outLine" "$2;
            }
        }
        else if( ($1 ~ /Config*/ || $1 ~ /Format*/) && !a[$1]++){
            outLine=$0;
        }
        else if( $1 ~ /[0-9]+/ ){
            if(!a[$1]++){
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
    sed -i '/^\s*$/d' $file && echo "" >> $file
    sed -i "/${word}/{G;h;d};/^\s*$/{g;p};H;d" $file
    sed -i '/^\s*$/d' $file && echo "" >> $file
}
###############################
# Main
oriFile="log.txt"
tmpFile="simParameterTmp.txt"
taskStartFlag=TaskBegin
taskEndFlag=TaskEnd
commentStartFlag=CommentBegin
commentEndFlag=CommentEnd
\cp -f $oriFile $tmpFile
echo "--------- output start -----------"
\rm -f MD5*

\rm $tmpFile
md5Num=0
declare -A md5Arr
for i in `seq 0 3`; do
    configStr=`cat tc_$i/$oriFile | grep Config`
    FormatStr=`cat tc_$i/$oriFile | grep Config`
    md5Str=`echo "$configStr$FormatStr" | md5sum | tr -d -c [0-9a-zA-Z]`
    md5File="MD5$md5Str.txt"
    cat tc_$i/$oriFile >> $md5File
    md5Arr[$md5Str]=1
done
for m in ${!md5Arr[*]}; do
    md5File="MD5$m.txt"
    sed -i '/^\s*$/d' $md5File
    sort -k1nr -k2n $md5File -o $md5File
    MergeResultFile $md5File $md5File
    PutWordsAhead $md5File "Source*"
    PutWordsAhead $md5File "Format*"
    PutWordsAhead $md5File "Config*"
    cat $md5File >> $tmpFile
done
\rm -f MD5*
echo "--------- result start -----------"
cat $tmpFile
