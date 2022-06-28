# -*- coding: utf-8 -*-
"""
Created on Wed Feb 16 12:26:42 2022

@author: aalvarez
"""

from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search
import time
import pandas as pd
import re

ref = r'\nReferences.?\n|\nREFERENCES.?\n|\sReferences.?\s|\sREFERENCES.?\s|References.?|REFERENCES.?|\nBibliography.?\n|\sBibliography.?\s'
refgex = re.compile(ref, re.I)

es = Elasticsearch([{'host': 'localhost', 'port': 9200}], timeout=60)
DatabaseName = 'bibliography-oa'



gene = 'Mex3a' #Introduce the desired word to search!
# field = 'FullText'
cath = ['title', 'Abstract', 'keywords', 'FullText', 'TextFigures', 'OCR']
toadd = '[^0-9a-zA-Z]'
generex = re.compile(toadd+re.escape(gene)+toadd, re.I)
df=pd.DataFrame(columns = ['cath', 'doi', 'title', 'journal', 'month', 'year', 'number_hits', 'pdf', 'keywords', 'Found_in','Screening', 'url', 'Abstract']) 

def addresult(number, hit, field):
          dftemp=pd.DataFrame()
          dftemp['doi'] = [hit['doi']]
          dftemp['title'] = [hit['title']]
          dftemp['journal'] = [hit['journal']]
          dftemp['month'] = [hit['month']]
          dftemp['year'] = [hit['year']]
          dftemp['number_hits'] = [[number]]
          dftemp['keywords'] =[hit['keywords']]
          dftemp['Found_in'] =['Body']
          dftemp['pdf'] = [hit['pdf']]
          dftemp['cath'] = [field]
          dftemp['Screening'] = [False]
          dftemp['url'] = [hit['Url']]
          dftemp['Abstract'] = [hit['Abstract']]
          return dftemp
      
start = time.time()
for field in cath:
    text = ''
    text2 = ''
    s = Search(using=es, index=DatabaseName).query("query_string", query= gene, default_field=field, default_operator= "AND")#▲.query("query_string", query= 'screening', default_field=field, default_operator= "AND")#.extra(from_=n, size=n+q)
    s = s.params(scroll='25m')
    # response = s.execute()
    kk = -1
    newdict = dict()
    for kk, hit in enumerate(s.scan()):
        a = (hit)
        if kk >350:
            print('more than 300 hits found, adding to list of longgenes...')
            break
        if field == 'keywords':
            for key in hit[field]:
                text2 += ' '+str(key) + ' '
        else:
            text2 = ' '+ hit[field]+ ' '
        newdict[hit['doi']]  = text2
        df = df.append(addresult(0, hit, field), ignore_index=True)
    if kk == -1:
        continue
    for jj, doi in enumerate(newdict):
        text = newdict[doi]
        posref = 0
        counter = -1
        counter2 = -1
        index = []
        for counter, match in enumerate(generex.finditer(text)):
            index.append(match.start())
        if len(re.findall(r"screen", text,re.I)) > 0:
            df.loc[(df.doi == doi ) & (df.cath == field),'Screening'] = True
        if counter >-1:
            df.loc[(df.doi == doi ) & (df.cath == field),'number_hits'] = counter+1
            if field == 'FullText':
                for match in refgex.finditer(text):
                    if (match.start() > (len(text)*2/3)):
                        posref = match.start()
                        # print("Reference found at position: ", posref) 
                        break
                    else:
                        posref = 0
                # print(posref)
                if posref<1:
                    continue
                for counter2, i in enumerate(index):
                    if i >= posref:
                        counter2 = counter2-1
                        break
                if counter2 == -1:
                    df.loc[(df.doi == doi ) & (df.cath == field),'Found_in'] = 'References'
                    
                    
group1 = ['title', 'Abstract', 'keywords']
group2 = ['FullText']
group3 = ['TextFigures', 'OCR']       
index1 = df[df['cath'].isin(group1)].index
index2 = df[df['cath'].isin(group2)].index
index3 = df[df['cath'].isin(group3)].index


# get list with dois

     
doi1 = {}
for field in group1:
    temp = list(df[df['cath']== field].doi)
    temp2 = list(df[df['cath']== field].index)
    for doi, index in zip(temp, temp2):
        if doi not in doi1.keys():
            doi1[doi] = index
doi2 = {}
for field in group2:
    temp = list(df[df['cath']== field].doi)
    temp2 = list(df[df['cath']== field].index)
    for doi, index in zip(temp, temp2):
        if (doi not in doi2.keys()) and (doi not in doi1.keys()):
            doi2[doi] = index          

doi3 = {}
for field in group3:
    temp = list(df[df['cath']== field].doi)
    temp2 = list(df[df['cath']== field].index)
    for doi, index in zip(temp, temp2):
        if (doi not in doi3.keys()) and (doi not in doi1.keys()) and (doi not in doi2.keys()) :
            doi3[doi] = index          
len(doi1)


# df.reset_index(inplace=True)
# df = df.set_index('doi')


folder= r'Z:\users\aalvarez\Python\PaperCrawler\Results'

nametosave = folder + '\Results-AARobot_for_'+gene+'_'+DatabaseName+'.xlsx'  
# tofind = [r"Mex3a", r"Mex3b", r"Mex3c", r"Mex3d", r"MEX3\s", r"EMP1" ]
with pd.ExcelWriter(nametosave) as writer:  
    #final_df.to_excel(writer, sheet_name = 'Total_data', index=False)
    for dois, name in zip([doi1, doi2, doi3], [group1, group2, group3]):
        tempdf = df.loc[list(dois.values())].sort_values(by=['number_hits'], ascending=False)
        tempdf.to_excel(writer, sheet_name = name[0], index=False)
        
        
end = time.time()

print(end-start, 'Secs')
