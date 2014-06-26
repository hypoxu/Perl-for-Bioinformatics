#!/bin/bash

# (C) Kranti Konganti
# This program is distributed as Artistic License 2.0
# 06/18/2014
# Coordinate with ncRNAscan output to parse out and add Infernal annotation to final ncRNA transcripts.

if [  -z "$FINAL_GTF" ]  ||
    [ -z "CM_TXT_OUT"  ] ||
    [ -z "CPC_TXT_OUT" ] ||
    [ -z "COV" ]; then
    echo -e "\nERROR!\n------\nUsage: $0 <FINAL_GTF> <CM_TXT_OUT> <CPC_TXT_OUT> <COV>\n";
    exit -1;
fi

grep noncoding $CPC_TXT_OUT | cut -d "|" -f 1 | sort -n | uniq | while read trid; do 
    trlen=`grep "$trid" $FINAL_GTF | grep -oP 'transcript_length \"\d+\"' | head -n 1 | perl -e '\$line = <>; if (\$line =~ m/.+?(\d+)/) {print \$1;}'`;
    hitlen=`grep "$trid" $CM_TXT_OUT | sort -k15,15nr | uniq | head -n 1 | awk '{if(\$10=="+") print \$9-\$8; else print \$8-\$9;}'`;
    annot=`grep "$trid" $CM_TXT_OUT | sort -k15,15nr | uniq | awk '{$1=""; sc=$15; for(i=3;i<=17;i++) $i=""; if (length($0) != 0) print $0, " | BitScore: ",sc}' | cut -d " " -f 2- | sed -e 's/\s\+/ /g' | head -n 1`;

    if [ -z "$trlen" ] || [ -z "$hitlen" ]; then
	calc_cov=0.0;
    else
	calc_cov=$(echo "scale=2; $hitlen * 100 / $trlen" | bc);
    fi
    
    if [ -z "$annot" ] || [[ $(echo "$calc_cov < $COV" | bc) -eq 1 ]]; then 
	annot='No Annotation'; 
    else
	annot="$annot | Coverage: "$calc_cov$per_symb;
    fi 

    grep "$trid" $FINAL_GTF | sed -e 's/Infernal.*//' | sed "s/$/ Infernal_prediction \"$annot\"\;/";
done;