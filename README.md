### Repository with code for two projects related to my PhD.

"clonal_Analysis per mice total analysis-Adrian-Alvarez" refers to an ImageJ macro that allows the batch quantification of series of images. Briefly, tomato+ objects (Clones obtain by lineage tracing) are detected, and based on the Euclidian distance of their closest points, are merged into same objects. To detect tumor cells, we use the size of the nuclei as the main parameter. With this the macro creates a mask to which the total area of tomato is relativized. 

"PaperDownloader_AdrianA_OpenAcessPapers"  is the code to download all the openacess papers. Briefly, the program looks for all the ids of the papers (dois), and then access individually the website using selenium. After this, it is able to find the pdf url. Then reads all the text from the pdf, including the Figures. This step is done by OCR. After pdf is read, file is removed, and data is inserted into an ElasticSearch Database.

"Create Excel with results.py" is the last piece of code that I use to search for text within all the papers using ElasticSearch. The code uses pandas to include the results in a excel format to be easily read by all users.

