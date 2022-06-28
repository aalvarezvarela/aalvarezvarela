### Repository with code for two projects related to my PhD.

"clonal_Analysis per mice total analysis-Adrian-Alvarez" refers to an ImageJ macro that allows the batch quantification of series of images. Briefly, tomato+ objects (Clones obtain by lineage tracing) are detected, and based on the euclidian distance of their closest points, are merged into same objects. To detect Tumor cells we use the size of the nucleai as the main parameter. With this the macro creates a mask to wich the total area of tomato is relativized. 

"PaperDownloader_AdrianA_OpenAcessPapers"  is the code to download all the openacess papers. Briefly, the program looks for all the ids of the papers (dois), and then acess individually the website using selenium. After this, it is able to find the pdf url. Then reads all the text from the pdf, inlcuding the Figures. This step is done by OCR. After pdf is read, file is removed, and data is inserted into an ElasticSearch Database.

the last piece of code is to search for text withing all the papers using Elastic Search. The code uses pandas to include the results in a excel format to be easily read by all users. 
