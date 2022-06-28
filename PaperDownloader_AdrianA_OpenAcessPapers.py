# -*- coding: utf-8 -*-
# -*- coding: utf-8 -*-
"""
Created on Tue Jan  4 16:47:44 2022

@author: Adrian
"""
"""
Wait this is SIRE PAPERS ONLY! Run first the open acess since there is a limit of papers you can download
"""

import random
from datetime import date
import datetime
from datetime import timedelta
import re
import os
from pathlib import Path
import fitz  # this is pymupdf
import tkinter as tk
from tkinter import filedialog
# from scidownl.scihub import *
import numpy as np
import pandas as pd
from pymed import PubMed
import time
#import scihub
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from bs4 import BeautifulSoup
import requests
from urllib.parse import unquote
import urllib
from bs4.element import Comment
import pytesseract
from PIL import Image
import argparse
import cv2
from elasticsearch import Elasticsearch
from elasticsearch_dsl import Search
import pickle
es = Elasticsearch([{'host': 'localhost', 'port': 9200}])
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'
TOSAVE = True
JSONPATH = r"D:\JSON files"
JSONPATHOS = "D:/JSON/JSON-OS/"
JSONPATHOA = "D:/JSON/JSON-OpenAcess/"
JSONPATHERROR = r"D:\JSON\JSON-OS-Error"
USER = 0

## Variables to change
DatabaseName = 'bibliography-oa'
#Dates to start and to end
datelast = '2000/01/01'
datestart = '2022/12/07'

#This would be the papers the script will skip
TO_SKIP =['news', 'comment', 'research briefing', 'prespectives', 'news & views', 'editorials', 'outlook', 'essay', 'community corner']
npapers= 500000
savepathpdf = r"C:\users\aalvarez\Paper4" # \ for downloaded folder


files = os.listdir(savepathpdf)
if len(files) > 0:
    for file in files:
        os.remove(savepathpdf+ '\\'+ file)
        time.sleep(1)

#to get position of references
ref = [r'\nReferences.?\n|\nREFERENCES.?\n', r'\sReferences.?\s|\sREFERENCES.?\s', r'References.?|REFERENCES.?',r'\nBibliography.?\n', r'\sBibliography.?\s']
#chech first if file exists
def Check_ESdatabase(doi, field ='doi'):
    in_database = False
    # s = Search(using=es, index=DatabaseName).query('match', cathegory=doi.split('\n')[0].replace(".", '/.')).extra(from_=0, size=30)
    if field == 'doi':
        s = Search(using=es, index=DatabaseName).query('query_string', query=doi.replace("/", '\/'), default_field=field, default_operator= "AND")
    else:
        s = Search(using=es, index=DatabaseName).query('query_string', query=doi.replace("/", '\/'), default_field=field, default_operator= "AND")
    try:
        for kk, hit in enumerate(s):
            if hit['doi'] == doi and field == 'doi':
                in_database = True
                break
            else:
                in_database = True
                break
    except:
        pass
    return in_database

Open_Source= ['"The EMBO journal"', '"EMBO molecular medicine"', '"eLife"', '"Science advances"', 
              '"Cell reports"', '"Nature communications"', '"Scientific reports"', '"PloS one"',
              '"Proceedings of the National Academy of Sciences of the United States of America"', 
              '"Nucleic acids research"', '"The Journal of cell biology"', '"iScience"', '"Stem cell reports"', 
              '"Cell Genomics"', '"PLoS genetics"', '"Genome biology"', '"PLoS computational biology"', 
              '"PLoS biology"', '"EMBO reports"', '"The Journal of clinical investigation"', '"BMC biology"', 
              '"BMC genomics"', '"BMC cancer"']

CommonJounrals = ['Blood', 'Nucleic acids research', 'PloS one', 'The Journal of cell biology', 'PLoS genetics', 
                  'PLoS computational biology', 'PLoS biology','The Journal of clinical investigation', 'Development (Cambridge, England)',
                  'Cancer discovery', 'Cancer research', 'The Journal of experimental medicine' ] 


JournalOA = ['"Nature"', '"Autophagy"', '"Immunity"', '"Nature medicine"', '"Cancer discovery"',
            '"Nature genetics"', '"Cell"', '"Cell stem cell"', '"Cancer cell"', '"Science"', '"Nature cancer"', 
            '"Science immunology"', '"Gastroenterology"', '"Science translational medicine"', 
            '"Cell death and differentiation"', '"Nature cell biology"', '"Molecular cell"', '"Cell metabolism"', 
            '"Oncogene"', '"Cell host microbe"', '"Nature immunology"', '"Blood"', '"Cancer research"', 
            '"Science signaling"', '"nature aging"', '"Current biology : CB"', '"Nature neuroscience"', 
            '"Nature metabolism"', '"Neuron"', '"The Journal of experimental medicine"', 
             '"Developmental cell"', '"Gut"', '"Development (Cambridge, England)"', '"The Journal of biological chemistry"',
             '"Lancet (London, England)"', '"The Lancet. Oncology"', '"The New England journal of medicine"']

Journals = Open_Source + JournalOA
#prepare query for pubmed
query = ''
t =0
for j in Journals:
    if t==0:
      query+=j+'[Journal]'
      t=1
    else:
        query+=(' OR ' +j+'[Journal]')
query +=' AND ("'+str(datelast)+'"[Date - Publication] : "'+str(datestart)+'"[Date - Publication])'
#search in pubmed
pubmed = PubMed(tool="MyTool", email="my@email.address")
results = pubmed.query(query, max_results=npapers)
#get results data
i = 0
dois = []
titles = []
journals = []
keywords = []
dates = []
abstracts = []
alreadyin=0
for article in results:
    if article.doi == None:
        continue
    doi = article.doi.split('\n')[0]
    if Check_ESdatabase(doi):
        print('doi already in Database',article.publication_date, doi)
        alreadyin +=1
        continue
    else:
        i = i+1
    try: 
        print(doi, article.journal, article.publication_date)
    except:
        pass
    titles.append(article.title)
    try:
        journals.append(article.journal)
        abstracts.append(article.abstract)
    except:
         journals.append('None')
         abstracts.append('None')
    try:
        keywords.append(article.keywords)
    except:
        keywords.append('None')
    try:
        dates.append(article.publication_date)
    except:
        dates.append('None')
    dois.append(doi)



pg = 0
#options chrome
options = webdriver.ChromeOptions()
options.add_experimental_option("prefs", {
  "download.default_directory": savepathpdf,
  "download.prompt_for_download": False,
  "download.directory_upgrade": True,
  "safebrowsing.enabled": True,
  "plugins.always_open_pdf_externally": True,
  "profile.managed_default_content_settings.images": 2
})
options.add_argument('ignore-certificate-errors')
options.add_argument('--ignore-ssl-errors=yes')
options.add_argument('--headless')
options.add_argument('--disable-gpu')
options.add_argument('--disable-blink-features=AutomationControlled')
options.add_argument('--no-sandbox')  
options2 = options
options.add_argument('window-size=1920x1080')
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36")
options2.add_argument('window-size=1024x1080')
options2.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win32; x32) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3729.169 Safari/537.36")


browsers = { 0 : webdriver.Chrome(options=options) , 1 : webdriver.Chrome(options=options2)}

#definitions

def pdfcounter(directory, endwith = '.pdf'):
    pdfs =[]
    for n in os.listdir(directory):
        if n.endswith(endwith):
            pdfs.append(n)
    return len(pdfs)
def download_wait(directory, timeout, nfiles,timeout2):
    """
    Wait for downloads to finish with a specified timeout.

    Args
    ----
    directory : str
        The path to the folder where the files will be downloaded.
    timeout : int
        How many seconds to wait until timing out.
    nfiles : int, defaults to None
        If provided, also wait for the expected number of files.

    """
    seconds = 0
    dl_wait = True
    dwnload = False
    inprogress = False
    pdfs = pdfcounter(directory)
    if pdfs == nfiles:
        dwnload = True  
        time.sleep(0.1)
        return dwnload
    while dl_wait and seconds <= timeout:
        print('Waiting to download pdf: ', seconds, 'Seconds')
        files = pdfcounter(directory, '.crdownload')
        pdfs= pdfcounter(directory)
        # dl_wait = False
        if files >0:
                dl_wait = True
                inprogress = True
                timeout2 = timeout
        elif inprogress ==True:
                inprogress = False
        if pdfs == nfiles:
            dl_wait = False
            break
        if (seconds > timeout2) and inprogress == False:
            print('link does not get pdf')
            return dwnload
        time.sleep(0.25)
        seconds += 0.25
    if seconds > timeout:
        print('Timeout')
        return 'timeout'
        # raise NameError('timeout')
    print('\x1b[6;30;42m'  + '  ... Pdf has been downloaded  ...' + '\x1b[0m' )
    dwnload = True
    time.sleep(0.05)
    return dwnload

def OCRfromPDF(page, rectangle):
    pix = page.get_pixmap(dpi=245, clip = rectangle)
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    img = np.array(img)
    # thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 21, 2) 
    text = pytesseract.image_to_string(get_grayscale(img), lang = 'eng', config='--oem 2 --psm 12') #1 or 12
    return text
def pdf_reader(pdfarticle):
    with fitz.open(pdfarticle) as doc:
        text = ""
        textOCR = ""
        textFigures = ""
        iii = 0
        for page in doc:
            iii += 1
            width= page.rect.width
            height = page.rect.height
            if len(page.get_images()) >0:    # printing number of images found in this page
                print(f"[+] Found {len(page.get_images())} images in page {iii}")
                temptext = page.get_text()
                imgtxt = ''
                minx1, maxx2, miny1, maxy2 = [],[], [],[]
                for n in page.get_image_info():
                    if n['bbox'][0] > width*0.05 and n['bbox'][1] > height*0.05 and n['bbox'][2] < width*0.95 and n['bbox'][3] < height*0.95:
                        minx1.append(n['bbox'][0])
                        maxx2.append(n['bbox'][2])
                        miny1.append(n['bbox'][1])
                        maxy2.append(n['bbox'][3])
                try:
                    rectangle = [min(minx1),  min(miny1),max(maxx2), max(maxy2)]
                    imgtxt = page.get_text(clip = rectangle)
                    if (sum([len(a) > 2 for a in re.sub(r'[^a-zA-Z\d\n\s:]', '', imgtxt).split()])) <1:                
                        print('..to OCR...')
                        textOCR += OCRfromPDF(page, rectangle)
                        # if len(textOCR)>3:
                        #     stext=[x for x in temptext.split() if len(x)>=3]
                        #     socr=[x for x in tempOCR.split() if len(x)>=3]
                        #     textOCR += " ".join(UncommonWords(set(stext), set(socr)))
                    else:
                        textFigures += imgtxt
                        temptext= temptext.replace(imgtxt, '')
                except:
                    imgtxt = ''
                text += temptext        
            else:
                text += page.get_text()  
                print("[!] No images found on page", iii)
        print('\x1b[6;30;42m'  + '  ... Pdf has been Read  ...' + '\x1b[0m' )
        textOCR = re.sub(r'[@*<«:&‘$»>£€¥"“¢;?]', '', textOCR)
        textOCR = " ".join([x for x in textOCR.split() if (len(x)>=3) and (re.search(r'[^\W\d_]', x))])
        return text, textOCR, textFigures

def count_mb_pdf(file_name):
    file_stats = os.stat(file_name)
    print(round(file_stats.st_size/(1024 * 1024),2), " MBs in downloaded pdf")
    return (file_stats.st_size/(1024 * 1024))

def tag_visible(element):
    if element.parent.name in ['style', 'script', 'head', 'title', 'meta', '[document]']:
        return False
    if isinstance(element, Comment):
        return False
    return True


def text_from_html(body):
    soup = BeautifulSoup(body, 'html.parser')
    texts = soup.findAll(text=True)
    visible_texts = filter(tag_visible, texts)  
    return u" ".join(t.strip() for t in visible_texts)



def get_grayscale(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)


def UncommonWords(A, B):
    #get words in B that are not in A, and returns them
    words = []
    for word in B:
        if word not in A:
            words.append(word)  
    # return required list of words
    return words
def df_result(doi, title, journal, keyword, date, pdf, posref, text, OCR, url, textfig):
        dftemp=pd.DataFrame()
        dftemp['doi'] = [doi]
        dftemp['title'] = [title]
        dftemp['journal'] = [journal]
        dftemp['Url'] = url
        try:
            dftemp['month'] = [date.month]
            dftemp['year'] = [date.year]
        except:
            dftemp['month'] = ['None']
            dftemp['year'] = ['None']
        dftemp['keywords'] =[keyword]
        dftemp['pdf'] = [pdf]
        dftemp['posRef'] = posref
        dftemp['Abstract'] = [abstract]
        dftemp['FullText'] = text
        dftemp['TextFigures']= textfig
        dftemp['OCR'] = OCR
        return dftemp
      
def searchintext(text, ref):
    #find position of reference
    for nn in ref:
       posref = 0
       for match in re.finditer(nn, text):
            posref = match.start()
            if (posref > (len(text)*2/3)): 
                print("Reference found at position: ", posref)
                return posref 
            else:
                return 0

def get_url_text_fromDOI(DOI, browser):
    doiurl = 'https://dx.doi.org/'
    browser.get(doiurl + DOI)
    element_present = EC.presence_of_element_located((By.TAG_NAME, 'body'))
    WebDriverWait(browser, 20).until(element_present)
    text = browser.find_element(By.TAG_NAME, 'body').text
    url = browser.current_url
    return url, text
def get_text_chrome(browser):
    try:
        element_present = EC.presence_of_element_located((By.TAG_NAME, 'body'))
        WebDriverWait(browser, 20).until(element_present)
        text = browser.find_element(By.TAG_NAME, 'body').text
        print("getting text from htlm")
        return text
    except: return ''
    

def checkpdflink(url, browser):
    #here pdf from selenium
    pdfurl = url + '.pdf'     
    pdfurl2 = None
    page_source = browser.page_source
    soup = BeautifulSoup(page_source, features="lxml")
    pos = page_source.find('elsevier')
    elsevier = False
    posscience = url.find('sciencedirect')
    stop = False
    if pos != -1 and posscience == -1:
            elsevier = True
            print('Elsevier paper detected')
    #check if paper should be skipped
    if elsevier == False:    
        for a in soup.find_all('a',{"title": "News"} ): 
            if a['title'] in ['News', 'Perspective','Policy Forum', 'In Depth']:
                return 'skip', a['title']
        for a in soup.find_all('div',{"class": "meta-panel__type"}): 
            for item in ['News', 'Report', 'Letter', 'Perspective','Policy Forum', 'In Depth', 'Focus', 'Feature', 'Education Forum', 'Careers', 'News & Analysis', 'News Focus']:
                if item in str(a) or 'News' in a:
                    return 'skip', item
        for a in soup.find_all('a', {"class": "c-breadcrumbs__link"}): 
                for span in a('span'):
                    for n in span:
                        if 'news' in n or n in TO_SKIP:
                            return 'skip', n
    #Now get all pdfs
    if posscience != -1:
        elsevier = False
        for a in soup.find_all('a', href=True):
            if 'main.pdf' in a['href']:
                    pdfurl = a['href'] 
                    break
            elif '.pdf' in a['href'] and 'pii' in a['href']:
                    pdfurl = a['href'] 
        if pdfurl.find('.com') == -1:
            pdfurl = url[0:url.find('.com')+4] + pdfurl
    elif elsevier == True:
        pdfurl = 'None'
        for a in soup.find_all('a', href=True):
            if '/action/showPdf' in a['href']:
                pdfurl = a['href']  
        if "https:" in pdfurl:
            pass
        elif pdfurl != 'None' and url.find('.com') != -1:
            pdfurl = url[0:url.find('.com')+4] + pdfurl
        elif pdfurl != 'None' and url.find('.org') != -1:
            pdfurl = url[0:url.find('.org')+4] + pdfurl
        if pdfurl == 'None':
            metatags = soup.find_all('meta')
            for tag in metatags:
                if "citation_pdf_url" in str(tag):
                    pdfurl = str(tag)[str(tag).find('http'): str(tag).find('pdf')+3]
                    break        
    elif journal in CommonJounrals or "BMC" in journal:
        metatags = soup.find_all('meta')
        for tag in metatags:
            if "citation_pdf_url" in str(tag) :
                pdfurl = str(tag['content'])
                break
            else:
                for a in soup.find_all('a', href=True):
                    if "c-pdf-download" in a['href']:
                        pdfurl= a['href']
                    if '/article/file' in a['href']:
                        # print(a['href'])
                        pdfurl = url[:url.find(a['href'][0:7])]+ a['href']
                        stop = True
                        break
            if stop:
                break
    elif 'EMBO' in journal:
            pdfurl = url.replace('full', 'pdfdirect')
    elif journal == 'Cancer discovery':
        pdfurl = url+'.full-text.pdf'   
    # elif journal == "Science advances":
    #     if url.find('doi/') !=-1:
    #           pdfurl= url[0:url.find('doi/')+4]+'pdf/'+ url[url.find('doi/')+4:]   
    elif journal == 'Genome biology':
        for a in soup.body.find_all('a', href=True):
            if "pdf-download" in str(a):
                    pdfurl= 'https:' + a['href']
                    break  
    elif journal == 'Autophagy':
        pdfurl = url.replace('full', 'pdf')
    elif journal == 'The New England journal of medicine':
        for a in soup.find_all('a', href=True):
            if '/pdf' in a['href']:
                pdfurl = a['href']  
                pdfurl = url[0:url.find('.org')+4] + pdfurl
                break
    # elif journal == 'Cancer discovery':
    #     pdfurl = url+'.full-text.pdf' 
    elif journal == 'Gut':
        for a in soup.find_all("a", class_="article-pdf-download", href = True):
            pdfurl =a['href']
            break
        if url.find('ub.edu') != -1:
                pdfurl = url[0:url.find('ub.edu')+6] + pdfurl
        if url.find('.com') != -1:
            pdfurl = url[0:url.find('.com')+4] + pdfurl
    elif 'Science' in journal or journal == 'Proceedings of the National Academy of Sciences of the United States of America':
        if url.find('doi/') !=-1:
            pdfurl= url[0:url.find('doi/')+4]+'pdf/'+ url[url.find('doi/')+4:]               
        if journal == 'Proceedings of the National Academy of Sciences of the United States of America' and url.find('doi/full') != -1:
            pdfurl = pdfurl.replace('/full', '')
            
    else:
       pdfurl2 = pdfurl[:-4]+'_reference.pdf'
    return pdfurl, pdfurl2
   
def checkbrowser(driver):      
    try:
        driver.title
        return 1
    except:
        print('Restarting Chrome')
        return 0


def clean_folder(path, dltc, limit =3):
    files = os.listdir(path)
    if dltc > limit and len(files) > 0:
        dltc = 0
        try:
            for file in files:
                os.remove(path+ '\\'+ file)
        except: pass
    return dltc 

def check_times(timelimit):
    global countermb
    global limitub
    if time.time() - countermb[USER+2] > timelimit-1:
           countermb[USER+2] = time.time()
           countermb[USER] = 0
           limitub[USER] = 0



def changeuser(user):
    if user == 0:
        user=1
    else:
        user =0
    return user


def skiptitles(title):
    skiptitle= ['Daily briefing', 'Podcast', 'Coronapod', 'podcast', 'Corrigendum', 'Correction:']
    for n in skiptitle:
        if n in title:
            print('Podcast detected')
            return True
    return False

def doi_Open_access_check(doi):
    pdfurl = ''
    root = 'https://api.openalex.org/works/doi:' 
    fin = False
    c = 0
    while fin == False and c<10:
        try:
            response = requests.get(root+doi)
            fin = True
        except:
            c +=1
            time.sleep(15)
    if response.status_code != 200:
        print(doi, 'not in OpenAlex')
        return None, ''
    is_oa = response.json()['open_access']['is_oa']
    oa_status = response.json()['open_access']['oa_status']
    if oa_status != 'gold' and is_oa == True:
        pdfurl = response.json()['open_access']['oa_url']
    if is_oa:
        print('\x1b[1;35;43m'  + '  ... Open Acess!! ...' + '\x1b[0m' )
        print(doi, 'is open access with code ', oa_status)
        pdfurl = response.json()['open_access']['oa_url']
        
    else:
        print('\x1b[3;30;43m'  + doi + ' not open acess :( ...' + '\x1b[0m' )
    print(pdfurl)
    return is_oa, pdfurl


limite = 'Usuari suspès temporalment'
doiurl = 'https://dx.doi.org/'
url_prev = ''
dltc = 0 #counter to refresh just in case
counter=0
counter2 = 0
counterweb = 0
counterpdf = 0
counterfree = 0


testurl='https://pubmed-ncbi-nlm-nih-gov.sire.ub.edu/'
restart=False

timecounter2 = 0
restart=[0,0]



for DOI, title, journal, key, date, abstract in zip(dois, titles, journals, keywords, dates, abstracts):
    try:
        start2 = time.time()
        pg += 1
        dltc += 1
        if Check_ESdatabase(DOI):
            print('doi already in Database: ', DOI, title, journal, date)
            continue 
        print(round(timecounter2/60/60, 2), 'hours running')
        elsevier = False
        text = ''
        textOCR = ''   
        textfigures = ''
        change_USER = False
        pdfread=False
        pdfurl = ''
        pdfurl2=''
        if skiptitles(title):
            continue
        if abstract is None:
            abstract = 'None'
        if title is None:
            title = 'None'
        if journal is None:
            journal = 'None'
     
        USER = changeuser(USER)
        #check browsers
        for browser in browsers:
            if checkbrowser(browsers[browser]) == 0:
                if browser == 0:
                    browsers[browser] = webdriver.Chrome(options=options)#open headless chrome1
                if browser == 1:
                    browsers[browser] = webdriver.Chrome(options=options2)
                time.sleep(1)
        for r in range(0,len(restart)):
            if restart[r] ==1:
               browsers[r].close()
               restart[r] = 0
               dltc=5
     #First Delate files in download folder
        dltc= clean_folder(savepathpdf, dltc, 2)

        #start to download
        downloadedpdf = False
        pdf = False
        pdfread=False
        wait = True
        print('Paper to download: ', DOI, title, journal)
        print(date)
        print("Paper ", pg, " out of ", len(dois), " total papers")
        print("Progress: ", (pg/len(dois))*100, '%')
        try:
            url, temptext =get_url_text_fromDOI(DOI, browsers[USER])
        except:
            print('Error loading DOI')
            restart[USER]=1 
            continue
        if len(re.findall('podcast', temptext, re.I)) > 3: 
            continue
        try:
            pdfurl, pdfurl2 = checkpdflink(url, browsers[USER])
        except:
            print('Error during geting link to download pdf')
            restart[USER]=1 
            continue
        if pdfurl =='skip':
            print('\x1b[0;31;40m'  + 'Skipping paper: ' + pdfurl2+ '\x1b[0m')
            continue
        counter += 1
        print('Trying open source pdf download: ' + pdfurl)
        nfiles= pdfcounter(savepathpdf)
        try:
            browsers[USER].get(pdfurl)
            downloadedpdf = download_wait(savepathpdf, 80, nfiles+1, 1)
            if downloadedpdf == 'timeout':
                restart[USER]=1       
            if pdfurl2 != None and downloadedpdf == False:
                timeoutd= 0.9
                print('Trying 2nd link, downloading pdf from: ' + pdfurl2)
                browsers[USER].get(pdfurl2)
                downloadedpdf = download_wait(savepathpdf, 50, nfiles+1, 0.5)
        except:
            print('Error in getting pdf')
            restart[USER]=1
            time.sleep(20)
            continue
        if downloadedpdf:
            wait = False
            counterfree += 1
            print('Paper downloaded without login')
        pdf = False
        if downloadedpdf == False:
            Openacess, pdfurloa = doi_Open_access_check(DOI)
            if Openacess and pdfurloa != pdfurl and pdfurloa != None:
                nfiles= pdfcounter(savepathpdf)
                browsers[USER].get(pdfurloa)
                downloadedpdf = download_wait(savepathpdf, 80, nfiles+1, 1)
            if downloadedpdf == 'timeout':
                restart[USER]=1
            if downloadedpdf:
                wait = False
                counterfree += 1
                print('Paper downloaded without login')
            else:
                print('\x1b[0;31;40m'  + ' Paper not Open Acess' + '\x1b[0m' )
            pdf = False
        if downloadedpdf == True:        
            pdfflag = 0
            while pdfflag <3:
                pdfflag += 1
                pdfarticle = sorted(Path(savepathpdf).iterdir(), key=os.path.getmtime)[-1]
                if str(pdfarticle).endswith('.crdownload'):
                    time.sleep(3)
                    pdfarticle = sorted(Path(savepathpdf).iterdir(), key=os.path.getmtime)[-1]
                else: pdfflag += 4
                if pdfflag == 2: raise NameError('noPDF')
            text, textOCR, textfigures = pdf_reader(pdfarticle)
            count_mb_pdf(pdfarticle)
            counterpdf += 1 
            pdfread=True
            try:
               os.remove(pdfarticle)
            except: pass
        elif pdfread==False: 
            continue
        #processing of text
        text = text.replace(abstract, "")
        text = text.replace(title, "")
        posref = searchintext(text, ref)
        document = df_result(DOI, title, journal, key, date, pdfread, posref, text, textOCR, url, textfigures)
        if TOSAVE:
                if len(text)<501:
                    name=JSONPATHERROR+'\\'+re.sub('/', '', DOI)+'.txt'
                    print('Text didnt match criteria.... Moving to error folder')
                else:
                    if '"' + journal + '"'  in Open_Source:
                        document['OA'] = 'OS'
                        name=JSONPATHOS+re.sub('/', '', DOI)+'.txt'
                    if '"' + journal + '"'  in JournalOA:
                        document['OA'] = 'OA'
                        name=JSONPATHOA+re.sub('/', '', DOI)+'.txt'    
                with open(name, 'wb') as f:
                    pickle.dump(document.iloc[0].to_dict(), f)
                    print('\x1b[2;37;44m'+ "Paper sent to .txt"+ '\x1b[0m')
        if len(text)>500:
            res = es.index(index=DatabaseName, document=document.iloc[0].to_json())
            print('\x1b[2;37;44m'+ "Paper sent to ElasticSearch Database"+ '\x1b[0m')
        end2 = time.time()
        print(f"{round(end2 - start2, 2)} sec for this paper")
        timecounter2 += end2 - start2
    except:
        print('error')
        continue


for b in browsers:
    browsers[b].close()
print('\x1b[0;31;40m'  + '  ... Done!! ...' + '\x1b[0m' )


