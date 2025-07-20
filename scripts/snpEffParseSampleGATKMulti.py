#!/usr/bin/python
'''
# This script will work on GATK merged samples only. 

#input will ne like:
#CHROM  POS     dbNSFP_rs_dbSNP142      REF     ALT     QUAL    DP      AC      AN      GEN[*].DP       GEN[*].GT       ANN[0].EFFECT   ANN[1].EFFECT   ANN[0].IMPACT   ANN[0].GENE     ANN[1].GENE     ANN[0].GENEID   ANN[0].FEATURE  ANN[0].BIOTYPE  ANN[0].RANK     ANN[0].HGVS_C   ANN[0].HGVS_P   LOF[*].GENE     LOF[*].NUMTR    LOF[*].PERC     dbNSFP_Polyphen2_HDIV_score     CADD    GERP    AF      1k_MAX  ExAC_AF dbNSFP_ESP6500_EA_AF    dbNSFP_ESP6500_AA_AF
1       69511   rs75062661      A       G       1598.8  131     8       8       15,26,56,0,34   1/1,1/1,1/1,./.,1/1     missense_variant        sequence_feature        MODERATE        OR4F5   OR4F5   ENSG00000186092 transcript      protein_coding  1/1     c.421A>G        p.Thr141Ala     .       .       .       0.0     7.183   .       1       .       0.894   0.8874293315596941      0.5441011235955057

#output will be like :
#CHROM  POS     rsid    REF     ALT     QUAL    DP      AC      AN      DP      DP_QIF_033_06   DP_QIF-04-05    DP_QIF_034_02   DP_QIF_031_04   DP_QIF_031_01
   GT      GT_QIF_033_06   GT_QIF-04-05    GT_QIF_034_02   GT_QIF_031_04   GT_QIF_031_01   EFFECT  EFFECT_2        IMPACT  GENE    GENE_2  GENEID  FEATURE BIOTYPE RANK    HGVS_C  HGVS_P  LOF.GENE        LOF.NUMTR       LOF.PERC        Polyphen2_HDIV_score    CADD    GERP    AF      1k_MAX  ExAC    ESP6500_EA      ESP6500_AA_AF
1       69511   rs75062661      A       G       1598.8  131     8       8       15,26,56,0,34   15      26      56      0       34      1/1,1/1,1/1,./.,1/1
     ALT     ALT     ALT     NA      ALT     missense_variant        sequence_feature        MODERATE        OR4F5   OR4F5   ENSG00000186092 transcript      protein_coding  '1/1    c.421A>G        p.Thr141Ala     .       .       .       0.0     7.183   .       1       .       0.894   0.8874293315596941      0.5441011235955057

'''

import sys
import os
import re
import gzip
list_temp=[]
sample_name=[]
vcf_file=sys.argv[2]
# Opening VCF files for getting all samples names
vcf_test=gzip.open(vcf_file,'rb')
for vcf in vcf_test:
	vcf=vcf.strip()
	if vcf.startswith("#CHROM"):
		sample_name=vcf.split("\t")[:]
		break
matches=[i for i in range(len(sample_name)) if "FORMAT" in sample_name[i]]
matches=int(matches[0] + 1)

# Opening TSV files
vcf_dir_file = sys.argv[1]
vcf_data = open(vcf_dir_file)
for vcf_line in vcf_data:
	check = 0
	val = 0
	test_arr =[]
        vcf_line = vcf_line.strip()
	if vcf_line.startswith("CHROM") or vcf_line.startswith("#CHROM"):
		temp_line = vcf_line.split("\t")[:]
		temp_line_temp=temp_line[:]
		x,y = [i for i in range(len(temp_line_temp)) if temp_line_temp[i].startswith("GEN")]
		m,n = x,y
		[temp_line.insert(x+1,"DP_" + i) for i in reversed(sample_name[matches:])]
		x,y = [i for i in range(len(temp_line)) if temp_line[i].startswith("GEN")]
		[temp_line.insert(y+1,"GT_" + i) for i in reversed(sample_name[matches:])]
		temp_out = [word.replace('dbNSFP_','').replace('ANN[0].','').replace('GEN[*].GT','GT').replace('GEN[*].DP','DP').replace('LOF[*]','LOF').replace('1000','1K').replace('LOF[*]','LOF').replace('rs_dbSNP142','rsid').replace('ANN[1].EFFECT','EFFECT_2').replace('ANN[1].GENE','GENE_2')for word in temp_line]
		#temp_out.remove('GEN[*]')
		header = "\t".join(temp_out)
		header = re.sub("_AF\t","\t",header)
		print header
		for index in range(len(temp_line_temp)):
			if "dbNSFP" in temp_line_temp[index]:
				list_temp.append(index)
			if "RANK" in temp_line_temp[index]:
				rank_index = index
	if not vcf_line.startswith("CHROM"):
                vcf_ann = vcf_line.split("\t")[:]
                for j in range(len(vcf_ann)):
			if j == rank_index:
				if not vcf_ann[j] == ".":
					a = "'" + vcf_ann[j]
					test_arr.append(a)
				else:
					test_arr.append(".")
			elif j == m:
				test_arr.append(vcf_ann[j])
				[test_arr.append(i) for i in vcf_ann[j].split(",")[:]]
			elif j == n:
				test_arr.append(vcf_ann[j])
				for i in vcf_ann[j].split(",")[:]:
					if "0/0" in i:
						i ="REF"
					elif "1/1" in i: 
						i = "ALT"
					elif "0/1" in i or "0/2" in i: 	
						i = "HET"
					elif "./." in i:
						i = "NA"
					else: i="OTHER"
					test_arr.append(i)
                        elif j in list_temp and "," in vcf_ann[j]:
                                vcf_arr=vcf_ann[j].split(",")[:]
				vcf_str="".join(vcf_arr)
				vcf_match=re.match("\.|\d+|\-", vcf_str)
				if not vcf_match:
                                              if (vcf_arr.count("D") >= 1):
                                                 test_arr.append("D")
                                              elif (vcf_arr.count("T") >= 1):
						 test_arr.append("T")
					      elif (vcf_arr.count("P") >= 1):
						 test_arr.append("P")
					      elif (vcf_arr.count("D") >= 1):
					         test_arr.append("D")
					      elif (vcf_arr.append("P") >= 1):
						 test_arr.append("P")  
					      else:
						 test_arr.append(".")	
			        if vcf_match: 
					val = max(vcf_arr)
					test_arr.append(val)
			else:
				test_arr.append(vcf_ann[j])
	if test_arr:
		print "\t".join(test_arr)
