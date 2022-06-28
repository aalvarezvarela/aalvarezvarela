// This slides had very fade contrast, also tomato not super bright, better with auto-macro
requires("1.52");
// Memory checker
memory = IJ.maxMemory();
RAM = 1.5* pow(10, 10);
if (parseInt(memory) < RAM) {
	showMessageWithCancel("RAM setted to "+ memory+ " bytes","Recommended RAM 15Gb... Continue?");
}
run("Collect Garbage");


//for selecting only where staining is
function detecttotalarea(ImageFolder, Imagetitle) {
	showStatus("detecttotalarea");
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}	
	open(ImageFolder+Imagetitle);
	roiManager("Add");
	a=getTitle();
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("RGB Stack");
	run("Convert Stack to Images");
	selectWindow("Red");
	rename("0");
	selectWindow("Green");
	rename("1");
	selectWindow("Blue");
	rename("2");
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	min[0]=220;
	max[0]=240;
	filter[0]="pass";
	min[1]=220;
	max[1]=238;
	filter[1]="pass";
	min[2]=219;
	max[2]=245;
	filter[2]="pass";
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  setThreshold(min[i], max[i]);
	  run("Convert to Mask");
	  if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","1");
	imageCalculator("AND create", "Result of 0","2");
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  close();
	}
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename(a);
	roiManager("select", 0);
	run("Clear Outside");
	roiManager("delete");roiManager("deselect");
	//selectWindow("ROI Manager"); run("Close");
	run("Invert");
	run("Analyze Particles...", "size=1000-Infinity show=Masks in_situ"); rename("totalArea");
	run("Create Selection");
	if (is("area") == 0) {
		total_area = 0;
		run("Close All");
		print("......................end of detecttotalarea............");
		print("......................error in this image, skipping to the next one............");
		return total_area
	}
	roiManager("Add");
	roiManager("Save", ImageFolder+Imagetitle+"total_area.zip");
	run("Clear Results");
	run("Set Measurements...", "area redirect=None decimal=2");
	run("Select None");
	//roiManager("measure");
	//total_area = getResult("Area", 0);
	//selectWindow("Results");
	//run("Close");
	//instead of measure, gethistogram and get maximum value
	selectWindow("totalArea");
	getStatistics(area, mean, gf , madx, std, histogram);
	total_area = histogram[histogram.length-1];
	run("Close All");
	print("......................end of detecttotalarea............");
	return total_area
}

function autogate(ImageFolder, Imagetitle, timepoint){
	open(ImageFolder+Imagetitle);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Clear Outside");
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
		}
	roiManager("Show All without labels");
	run("Colour Deconvolution", "vectors=H&E");
	selectWindow(Imagetitle + "-(Colour_3)");close();
	selectWindow(Imagetitle + "-(Colour_1)");rename("temp-DAPI"); run("Duplicate...", " "); rename("color1");
	selectWindow(Imagetitle + "-(Colour_2)"); close();
	setBackgroundColor(255, 255, 255);
	selectWindow(Imagetitle);
	run("8-bit");
	if (timepoint == "initial timepoint"){
		peak = 100;
		peak2 = 100;
	}
	else {
		peak = 100;
		peak2 = 100;
	}
	getStatistics(area, mean, min, max, std, histogram);
   	//create histogramo with no values of 255 etc
   	histogram2= Array.trim(histogram, 150);
   	//histogram with no 0
	for (n=0; n<histogram2.length; n++){
	 if ((histogram2[n] == 0) & (n>20)){
	   	histogram2[n] = (histogram2[n-1]+histogram2[n+1])/2;
	   	}
	 if ((histogram2[n] == 0) & (n==0)){
	  	histogram[n] = histogram2[n+1];
	  }
	 if ((histogram2[n] == 0) & (n==histogram2.length-1)){
	   	histogram2[n] = histogram2[n-1];
	   	}
	 }
	 Plot.create("Detecting Histogram Peaks", "X", "Y", histogram2);
	 Plot.show;
	 run("RGB Color");
	 //find maxima
	 maxLocs= Array.findMaxima(histogram2, peak);

	 // print("\\Clear");
	 print("\nMaxima (descending strength): ");
	 for (jj= 0; jj < maxLocs.length; jj++){
	    x= maxLocs[jj];
	    y = histogram2[x];
	    toUnscaled(x, y);
	    setForegroundColor(255, 0, 0);
	    makeOval(x-5, y-5, 9, 9);
	    run("Invert");
	    run("Fill", "slice");
	    setBackgroundColor(255, 255, 255);
	    }
	   // find minima
	minLocs= Array.findMinima(histogram2, peak2, 1);
	// print("\\Clear");
	print("\nMinima (descending strength): ");
	Array.print(minLocs);
	for (jj= 0; jj < minLocs.length; jj++){
	    x= minLocs[jj];
	    y = histogram2[x];
	    toUnscaled(x, y);
	    setForegroundColor(0, 54, 255);
	    makeOval(x-5, y-5, 9, 9);
	    run("Invert");
	    run("Fill", "slice");
	    setBackgroundColor(255, 255, 255);
		}
	
	selectWindow("Detecting Histogram Peaks");run("Close");
	//roiManager("Show All without labels");
	//run("8-bit Color", "number=256");
	//saveAs(".jpeg", ImageFolder+"Plot_"+Imagetitle); run("Close");
	if (minLocs.length == 0){
	 	selectWindow(Imagetitle);
	 	upper = 50;
	 	//run("Close All");
	 	print("......................end of autogate............");	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);	print("Time: "+hour+ ":" + minute +":" + second);
	 	selectWindow(Imagetitle);run("Close");
	 	return upper
	 }
	thresholdtoapply = minLocs[0] + 10;
	if ((minLocs[0] < 15) & (minLocs.length > 1)) {
		thresholdtoapply = minLocs[1]+5;	
	}
	if ((minLocs[0] < 15) & (minLocs.length < 1)) {
		thresholdtoapply = minLocs[0]+15;	
	}
	if (thresholdtoapply > 70) {
		upper = 45;
		thresholdtoapply = upper;
	}
	if ((thresholdtoapply < 10) & (timepoint == "initial timepoint")) {
		upper = 45;
		thresholdtoapply = upper;
	}
	//run("Close All");
	print("......................end of autogate............");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("Time: "+hour+ ":" + minute +":" + second);
	selectWindow(Imagetitle);
	run("Close");
	return thresholdtoapply
}	
function autogate3(ImageFolder,Imagetitle, timepoint){
	showStatus("autogate3");
	open(ImageFolder+Imagetitle);
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Colour Deconvolution", "vectors=H&E");
	selectWindow(Imagetitle); close();
	selectWindow(Imagetitle + "-(Colour_3)");close();
	selectWindow(Imagetitle + "-(Colour_1)");rename("temp-DAPI"); run("Duplicate...", " "); rename("color1");
	selectWindow(Imagetitle + "-(Colour_2)"); rename("tdtomato");
	setAutoThreshold();
	getThreshold(lower, upper);
	if (timepoint == "late timepoint") {
		thresholdtoapply = upper-15;
	}
	else {
		thresholdtoapply = upper-5;
	}
	if (thresholdtoapply > 155) {
		thresholdtoapply = 120;
	}
	run("Collect Garbage"); wait(500);
	print("......................end of autogate3............");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("Time: "+hour+ ":" + minute +":" + second);
	return thresholdtoapply
}
function DetectEpethilium(ImageFolder, Imagetitle, thr, timepoint){
	showStatus("DetectEpethilium");
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
		}
	setBackgroundColor(255, 255, 255);
	//options for adjust thresholds
	
	selectWindow("color1"); //run("Duplicate..."); 

	//rename("color1");
	if (timepoint == "late timepoint" ) {
		q = -30;
		setAutoThreshold("Otsu"); 
	}
	else {
		q = 10;
		setAutoThreshold("Otsu"); 
	}
	//This goes out as I dont want the autogate on for late timepoint!
	//
	//if (timepoint == "late timepoint" ) {
	//	open(ImageFolder+Imagetitle);
	//	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	//	roiManager("Show All without labels");
	//	run("Colour Deconvolution", "vectors=H&E");
	//	selectWindow(Imagetitle + "-(Colour_3)");close();
	//	selectWindow(Imagetitle + "-(Colour_2)");close();
	//	selectWindow(Imagetitle + "-(Colour_1)"); rename("temp-DAPI");
	//}
	//


	//delete rois small debris nucleai
	//setAutoThreshold(); 
	//setAutoThreshold("Otsu"); 
	getThreshold(lower, upper);
	setThreshold(lower, upper+q); //19 for initial timepoint; 18 for Later timepoint

	//load roi clones
	if (File.exists(ImageFolder+Imagetitle+"detected_clones_mask.zip") == 1){
		roiManager("Open", ImageFolder+Imagetitle+"detected_clones_mask.zip");
		selectWindow("color1");
		setForegroundColor(0, 0, 0);
		roiManager("select", 0);
		run("Fill");
 		roiManager("deselect");selectWindow("ROI Manager");run("Close"); roiManager("show all with labels");
	}

	selectWindow("color1");
	run("Analyze Particles...", "size=15-Infinity show=Masks");
	rename("Mask-Dapi-temp");
	run("Close-");
	run("Watershed");
	run("Analyze Particles...", "size=0-350 show=Masks in_situ");
	run("Create Selection");
	if (is("area") == 1) {
		roiManager("Add");
		selectWindow("color1");
		//setAutoThreshold("Otsu"); getThreshold(lower, upper);
		//setThreshold(lower, upper+q);
		roiManager("select", 0);
		//setForegroundColor(255, 255, 255); 
		run("Clear");
		roiManager("delete"); ;selectWindow("ROI Manager");run("Close"); roiManager("show all with labels");
	}
	selectWindow("color1");
	roiManager("deselect"); roiManager("Show All without labels");
	run("Analyze Particles...", "size=15-Infinity show=Masks");
	rename("Mask-Dapi-temp2");
	run("Close-");
	run("Maximum...", "radius=2");run("Minimum...", "radius=2");
	run("Analyze Particles...", "size=0-1000 show=Masks in_situ");
	run("Create Selection");
	if (is("area") == 1) {
		roiManager("Add");
		selectWindow("color1");
		roiManager("select", 0);
		//setForegroundColor(255, 255, 255); 
		run("Clear");
		roiManager("delete"); selectWindow("ROI Manager");run("Close"); roiManager("show all with labels");
	}
	else {
		selectWindow("color1");
		//setAutoThreshold("Otsu"); getThreshold(lower, upper);
		//setThreshold(lower, upper+q);
	}
	selectWindow("Mask-Dapi-temp2"); close();
	//load again the clones
	if (File.exists(ImageFolder+Imagetitle+"detected_clones_mask.zip") == 1){
		roiManager("Open", ImageFolder+Imagetitle+"detected_clones_mask.zip");
		selectWindow("color1");
		setForegroundColor(0, 0, 0);
		roiManager("select", 0);
		run("Fill");
 		roiManager("deselect");selectWindow("ROI Manager");run("Close"); roiManager("show all with labels");
	}
	
	
	roiManager("deselect"); roiManager("Show All without labels");
	x=3000;
	y=2000;
	n=0;
	while (n<2){
		selectWindow("color1"); 
		run("Analyze Particles...", "size=500-Infinity show=Masks");
		run("Close-");//run("Close-");
		run("Maximum...", "radius=2");run("Close-");
		run("Invert");
		run("Analyze Particles...", "size="+x+"-Infinity show=Masks in_situ");
		run("Invert");
		run("Analyze Particles...", "size="+y+"-Infinity show=Masks in_situ");
		if (roiManager("count")>0){
			roiManager("select", 0);
			run("Fill");
			run("Select None");	
			roiManager("delete");
		}
		run("Analyze Particles...", "size=200-Infinity show=Masks in_situ"); rename("mask epethilial");
		run("Create Selection");
		if (is("area") == 1) {
			roiManager("Add");
			n=3;
		}
		else {
			print("Epethilium not detected, lowering thershold by half");
			n++;
			x=x/2;
			y=y/2;
		}
	}
	
	setForegroundColor(255, 255, 255);
	//selectWindow("ROI Manager");run("Close");
	if (roiManager("count") > 0) {
		roiManager("deselect");
		roiManager("Save", ImageFolder+Imagetitle+"total_Epethilial_area.zip");
		//run("Set Measurements...", "area redirect=None decimal=2");
		//roiManager("measure");
		selectWindow("mask epethilial");
		run("Select None");
		getStatistics(area77, mean77, min77, max77, std, histogramep);
		epethilial_area = histogramep[histogramep.length-1];
		//epethilial_area = getResult("Area", 0);
		//selectWindow("Results"); run("Close");
		//count nucleai in detected area
		selectWindow("mask epethilial"); close();selectWindow("color1"); close(); run("Collect Garbage"); wait(500);
		selectWindow("temp-DAPI");
		roiManager("select", 0); run("Clear Outside");
	}
	else {
		selectWindow("mask epethilial"); close(); selectWindow("color1"); close(); run("Collect Garbage"); wait(500);
		epethilial_area = 0;
	}
	
	selectWindow("temp-DAPI");
	//setAutoThreshold(); getThreshold(lower, upper);
	setThreshold(lower, upper-25+q);
	run("Analyze Particles...", "size=10-infinity show=Masks in_situ");
	run("Close-");
	run("Invert");
	run("Analyze Particles...", "size=30-infinity show=Masks in_situ");
	run("Invert");
	run("Watershed");
	run("Analyze Particles...", "size=10-infinity show=Nothing summarize");
	selectWindow("Summary");
	nDapi = Table.getColumn("Count");
	nDapi = nDapi[0];	
	run("Close");
	run("Close All");
	//variable to retrieve nDAPI and area of the selected epethilia
	epethilial_results = Array.concat(epethilial_area, nDapi);
	print("......................end of DetectEpethilium............");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("Time: "+hour+ ":" + minute +":" + second);
	return epethilial_results;
}
													

function TomatoDetector(ImageFolder, Imagetitle, threshold, distance, scsize, timepoint){
	showStatus("TomatoDetector");
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
		}
	run("Clear Results");
	//open(ImageFolder+Imagetitle);
	//run("Clear Outside");
	//run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	//roiManager("Show All without labels");
	//run("8-bit");
	selectWindow("tdtomato");
	setThreshold(0, threshold);
	run("Select None");
	if (timepoint == "late timepoint" ) {
		run("Analyze Particles...", "size=240-Infinity show=Masks circularity=0.05-1 summarize"); //Include circularity check
	}
	else {
		run("Analyze Particles...", "size=140-Infinity show=Masks circularity=0.05-1 summarize"); //Include circularity check
	}
	run("Close-");
	rename("mask1");
	//results without merging
	selectWindow("Summary"); IJ.renameResults("Results");
	clonesnomerged = getResult("Count", 0);// print(clonesnomerged);
	avsizenomerged= getResult("Average Size", 0);// print(avsizenomerged);
	selectWindow("Results");run("Close");
	//watershed for initial timepoint
	if (timepoint != "late timepoint") {
		run("Duplicate...", " "); rename("tempp");
		run("Watershed");
		run("Analyze Particles...", "size=240-Infinity show=Masks summarize");
		rename("tempp2");
		selectWindow("Summary"); IJ.renameResults("Results");
		avsizenomerged_watershed= getResult("Average Size", 0);
		selectWindow("Results");run("Close");
		selectWindow("tempp");close(); selectWindow("tempp2");close();
	}
	selectWindow("mask1");
	run("16-bit");
	run("Multiply...", "value=1000");
	run("Duplicate...", "title=Copy");
	run("Maximum...", "radius="+distance/2);
	run("Minimum...", "radius="+distance/2);
	setThreshold(1,65535);
	run("Analyze Particles...", "size=140-Infinity show=[Count Masks] add");//distance in pixels
	if (roiManager("count") == 0){
		clonalresults =newArray(0,0,0,clonesnomerged,avsizenomerged,0);
		selectWindow("tdtomato");
		run("Close");
		print("......................tomato_detector............");
		//run("Close All");
		return clonalresults;
	}
	rename("mask2");
	run("Random");resetMinAndMax();
	roiManager("Save", ImageFolder+Imagetitle+"detected_clones_merged.zip");
	imageCalculator("AND", "mask2","mask1");
	selectImage("mask2");
	run("Select None");
	getHistogram(vals,counts,65536);
	getStatistics(area,mean,min,max);
	run("Clear Results");
	row = 0;
	for (i=1; i<=max; i++){
		if(counts[i]>0){
			setResult("Cluster Label", row, i);
	      	setResult("Area (pix)", row, counts[i]);
	      	row++;
		}
	}
	updateResults();
	selectWindow("Results");
	clonal_area = 0;
	for (i = 0; i < nResults; i++) {
		temp = getResult("Area (pix)", i);
		setResult("Cells per clone", i, (temp/scsize));
		clonal_area = clonal_area + temp;
	}	
	saveAs("Results", ImageFolder+Imagetitle +"Individual clones results.xls");
	numberclones = nResults;
	averageclonesize = clonal_area/numberclones;
	run("Clear Results");
	clonalresults = Array.concat(clonal_area,numberclones); clonalresults = Array.concat(clonalresults,averageclonesize);
	clonalresults = Array.concat(clonalresults,clonesnomerged); clonalresults = Array.concat(clonalresults,avsizenomerged);
	selectImage("mask2");
	selectWindow("ROI Manager");run("Close");
	setThreshold(1, 65535);
	run("Create Selection"); roiManager("add");
	roiManager("Save", ImageFolder+Imagetitle+"detected_clones_mask.zip");
	selectImage("mask2"); run("8-bit");
	saveAs("tiff", ImageFolder+Imagetitle + " color mask.tif"); close();
	if (timepoint == "late timepoint" ) {
		//run("Close All");
	}
	else {
		clonalresults = Array.concat(clonalresults,avsizenomerged_watershed);
	}
	selectWindow("Copy"); close();//selectWindow("tdtomato"); close(); 
	run("Collect Garbage"); wait(500);
	print("......................tomato_detector............");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	print("Time: "+hour+ ":" + minute +":" + second);
	selectWindow("tdtomato");
	run("Close");
	return clonalresults;
}

function frequences(ImageFolder, Imagetitle, sclimit, smalllimit, midlimit, x){
	showStatus("frequences");
	run("Clear Results");
	if (isOpen("Results")){
		selectWindow("Results"); run("Close");
	}
	if (File.exists(ImageFolder+ Imagetitle + "Individual clones results.xls") == 0){
		results = newArray(0,0,0,0);
		print("file with clonal results not found");
		return results;
	}
	open(ImageFolder+ Imagetitle + "Individual clones results.xls");
	wait(250);
	selectWindow(Imagetitle + "Individual clones results.xls");
	IJ.renameResults("Results");
	if (x==0) {
		cells_per_clone = Table.getColumn("Cells per clone");
	}
	else {
		cells_per_clone2 = Table.getColumn("Area (pix)");
		cells_per_clone = newArray();
		for (ii = 0; ii < cells_per_clone2.length; ii++) {
			cells_per_clone = Array.concat(cells_per_clone,(cells_per_clone2[ii]*x));
		}
	}
	//counters
	sc = 0;
	small = 0;
	mid = 0;
	large = 0;
	for (i = 0; i < cells_per_clone.length; i++) {
		if (cells_per_clone[i] < sclimit) {
			sc = sc + 1;			
		}
		if ((cells_per_clone[i] >= sclimit) & (cells_per_clone[i] < smalllimit)) {
			small = small + 1;			
		}
		if ((cells_per_clone[i] >= smalllimit) & (cells_per_clone[i] < midlimit)) {
			mid = mid + 1;			
		}
		if (cells_per_clone[i] >= midlimit){
			large = large + 1;			
		}
	}
	//print( "this is single cell " + sc);
	total = sc + small+ mid+ large;
	total = total/100;
	results = Array.concat(sc/total,small/total,mid/total, large/total);
	//Array.print(results);
	selectWindow("Results"); run("Close");
	return results;
}


function createarraychannel(Filelist, channel) {
	channelarrey = newArray();
	for (n=0; n<Filelist.length; n++){
		if ((indexOf(Filelist[n], "Plot") == -1) & (indexOf(Filelist[n], "color mask") ==-1)) {
			if( (indexOf(Filelist[n], channel) != -1) & (endsWith(Filelist[n],".tif"))) {
				channelarrey = Array.concat(channelarrey, Filelist[n]);
		}
		
		}
	}
	return channelarrey;
}

function occurencesInArray(array, value) {
    count=0;
    for (a=0; a<lengthOf(array); a++) {
        if (array[a]==value) {
            count++;
        }
    }
    return count;
}

function index(a, value) {
	for (i=0; i<a.length; i++)
          if (a[i]==value) return i;
    return -1;	
} 

//create dialog
Dialog.create("Options for clonal analysis");
items = newArray("initial timepoint", "late timepoint");
Dialog.addChoice("Select time point to be analyzed", items, "late timepoint");
Dialog.addCheckbox("Customed?", false);


Dialog.show();
timepoint = Dialog.getChoice();
check = Dialog.getCheckbox();

if (timepoint == "initial timepoint" ) {
	scsize = 530; //in pixels
	distance = 0.5;
	min = 150;
}
else {
	scsize = 530; //in pixels
	distance = 26; //in pixels
	min = 250;
}
if (check == true) {
	Dialog.create("Options for clonal analysis");
	Dialog.addNumber("Size of a single cell in pixels", 120);
	Dialog.addNumber("Distance to be consider same clone", 10);
	Dialog.addNumber("min size to be analyzed", 150);
	//Dialog.addCheckbox("Autogate?", true);
	Dialog.show();
	scsize = Dialog.getNumber();
	distance = Dialog.getNumber();
	min = Dialog.getNumber();
	//agate = Dialog.getCheckbox();
}

function resultspermice() {
	print("2sjd");
	
}

// clonal size options
sclimit = 2.5;
smalllimit = 6;
midlimit = 16;


//macro core
run("Options...", "iterations=1 count=1 do=Nothing");
setBackgroundColor(255, 255, 255);
run("Set Measurements...", "area redirect=None decimal=2");
// select folder that contains all the folders	  
ImageFolder = getDirectory("Pick the  root folder with the images to be analyzed");
FileListfolders = getFileList(ImageFolder);
run("Close All");
if(isOpen("ROI Manager")){
	selectWindow("ROI Manager");
	run("Close");
	}
folders = newArray();
for (i=0;i<FileListfolders.length;i++){ 
	tempfolder = ImageFolder + FileListfolders[i];
	if (File.isDirectory(tempfolder)){
		folders = Array.concat(folders,tempfolder);
	}
}
// load Random.lut file, should be either in the selecter folder or it will ask for it
Rlut= "Random.lut";
t = getDirectory("luts");
B = getFileList(t);
//Array.print(B);
count = occurencesInArray(B, Rlut);
//print(count);
if (count == 0){
	if (occurencesInArray(FileListfolders,Rlut) > 0){
		open(ImageFolder+Rlut);
	}
	else {
		Rlutpath = File.openDialog("Random.lut not found, select file");
		open(Rlutpath);
	}
	saveAs("LUT", t+Rlut); close();
}
// variable to get all samples per folder
samples3 = newArray();
headers2 = "\\Headings: Sample \t Roi \t total Area \t total Epethilial Area \t Epethilial/total Area \t Tom+ area \t % Tom+/total-area \t % Tom+/Epethilial area \t number nucleai per area \t number of clones \t number clones/ total-area \t number clones/ Epethilial-area \t average size of clones \t threshold \t cells per clone \t % Single Cells \t % Small clones ("+smalllimit+") \t % Mid clones ("+midlimit+") \t  % Large clones \t cells per clone(with DAPI) \t % Single Cells (with DAPI) \t % Small clones ("+smalllimit+") (with DAPI) \t % Mid clones ("+midlimit+") (with DAPI) \t  % Large clones (with DAPI)  \t number of unmerged clones \t non-merged clones / total area \t non-merged clones / epethilial area \t Average size of unmerged clones \t Average size of unmerged clones (nucleai) \t average size of clones Watershed (only initial timepoint) \t watershed cells per clone \t watershed cells per clone (DAPI)";
headers4 = "Sample \t Roi \t total Area \t total Epethilial Area \t Epethilial/total Area \t Tom+ area \t % Tom+/total-area \t % Tom+/Epethilial area \t number nucleai per area \t number of clones \t number clones/ total-area \t number clones/ Epethilial-area \t average size of clones \t threshold \t cells per clone \t % Single Cells \t % Small clones ("+smalllimit+") \t % Mid clones ("+midlimit+") \t  % Large clones \t cells per clone(with DAPI) \t % Single Cells (with DAPI) \t % Small clones ("+smalllimit+") (with DAPI) \t % Mid clones ("+midlimit+") (with DAPI) \t  % Large clones (with DAPI) \t number of unmerged clones \t non-merged clones / total area \t non-merged clones / epethilial area \t Average size of unmerged clones \t Average size of unmerged clones (nucleai) \t average size of clones Watershed (only initial timepoint) \t watershed cells per clone \t watershed cells per clone (DAPI)";
if (isOpen("Summary tomato+ clones")){
	print("[Summary tomato+ clones]", "\\Clear");
	}
else{
	run("Table...", "name=[Summary tomato+ clones] width=1450 height=400 menu");
	print("[Summary tomato+ clones]", headers2);
	}	
if (isOpen("Summary tomato+ clones2")){
	print("[Summary tomato+ clones2]", "\\Clear");
	}
else{
	run("Table...", "name=[Summary tomato+ clones2] width=1450 height=400 menu");
	print("[Summary tomato+ clones2]", headers2);
	}	




// loop to create
for (y=0; y<folders.length; y++){
	if (y != 0) {
		print("[Summary tomato+ clones]", "\t");
		print("[Summary tomato+ clones]", headers4);
	}
	FileList = getFileList(folders[y]);
	c1="Tomato";
	imagesc1 = createarraychannel(FileList, c1);
	//samples
	samples= newArray();
	samples2 = newArray();
	for (i=0;i<FileList.length;i++){ 
		print(i);
		if((endsWith(FileList[i], ".tif")) & (indexOf(FileList[i], "Plot") == -1)){
			for (ii = 0; ii < lengthOf(FileList[i]); ii++) {
				letter = substring(FileList[i], ii, ii+1);
				if ((isNaN(letter)) & (letter != "-") & (letter != " ") & (letter != "_")){
					indexletra = ii;
					break;
				}
			}
			Sample = substring(FileList[i], 0,indexletra);
			//te = substring(FileList[i], 0, indexOf(FileList[i], "-")+5);
			samples2 = Array.concat(samples2,Sample);
			if( occurencesInArray(samples, Sample) ==0){
				samples = Array.concat(samples, Sample);
				samples3 = Array.concat(samples3, Sample);
			}
		}	
	}
	//prepare results
	if (isOpen("Results tomato+ clones")){
		print("[Results tomato+ clones]", "\\Clear");
	}
	else{
		run("Table...", "name=[Results tomato+ clones] width=1450 height=400 menu");
		print("[Results tomato+ clones]", headers2);
	}
	//loop for all images, real macro
	for (i=0; i<imagesc1.length; i++){
		detected_area = detecttotalarea(folders[y], imagesc1[i]);
		if (detected_area == 0) {
			continue;
		}
		thr = autogate3(folders[y], imagesc1[i], timepoint);
		print("this is the threshold: " + thr);
		clones = TomatoDetector(folders[y], imagesc1[i], thr, distance, scsize,timepoint );
		Epethilium_area = DetectEpethilium(folders[y], imagesc1[i], thr, timepoint);	
		// create x-variable to estimate nDAPI per pixel to better calulate size
		x = Epethilium_area[1]/(Epethilium_area[0]-clones[0]);
		if (Epethilium_area[0]> detected_area) {
			Epethilium_area[0] = detected_area;
		}
		run("Collect Garbage");
		wait(1000);
		distribution = frequences(folders[y], imagesc1[i], sclimit, smalllimit, midlimit,0);
		distribution2 = frequences(folders[y], imagesc1[i], sclimit, smalllimit, midlimit, x);
		results = samples2[i]+"\t"+substring(imagesc1[i],(lengthOf(imagesc1[i])-9),(lengthOf(imagesc1[i])-4))+"\t"+ detected_area + "\t" + Epethilium_area[0] + "\t" + Epethilium_area[0]/detected_area + "\t"+ clones[0] + "\t"+ (clones[0]/detected_area)*100 + "\t"+ (clones[0]/Epethilium_area[0])*100+  "\t" + x + "\t" + clones[1] + "\t" + clones[1]/detected_area + "\t" + clones[1]/Epethilium_area[0] + "\t" + clones[2] + "\t"+ thr + "\t" + (clones[2]/scsize) +"\t"+ distribution[0] + "\t" + distribution[1] + "\t"+ distribution[2] +  "\t" + distribution[3] + "\t" + (clones[2]*x) +"\t"+ distribution2[0] + "\t" + distribution2[1] + "\t"+ distribution2[2] +  "\t" + distribution2[3] + "\t"+ clones[3] + "\t" + (clones[3]/detected_area)*100 + "\t"+ (clones[3]/Epethilium_area[0])*100 + "\t" + clones[4]/scsize + "\t" + clones[4]*x ;    
		if (timepoint == "late timepoint") {
			results = results + "\t"+ "N/A" +"\t"+ "N/A" +"\t"+ "N/A";
		}
		else {
			results = results + "\t"+ clones[5]+"\t"+ clones[5]/scsize+"\t"+ clones[5]*x;
		}
		print("[Results tomato+ clones]", results);
		print("[Summary tomato+ clones]", results); print("[Summary tomato+ clones2]", results);
		selectWindow("Results tomato+ clones");
		if (samples.length==0) {
			continue;
		}
		IJ.redirectErrorMessages();
		selectWindow("Results tomato+ clones");
		saveAs("Results", folders[y]+ samples[0] + " results of clonal analysis with distance "+distance+" .xls");
		run("Collect Garbage");
		wait(4000);
	}
	//run("Close All");
	print("no more images to anayze in folder " + (y+1) + " of " + folders.length);
	if(isOpen("ROI Manager")){
			selectWindow("ROI Manager");
			run("Close");
	}
	selectWindow("Results tomato+ clones");
	if (samples.length>0) {
		IJ.redirectErrorMessages();
		selectWindow("Results tomato+ clones");
		saveAs("Results", folders[y]+ samples[0] + " results of clonal analysis with distance "+distance+" .xls");
		}
	run("Close");
}
if(isOpen("Results")){
	selectWindow("Results"); run("Close");
}






selectWindow("Summary tomato+ clones");
name = "summary of clonal analysis with distance "+distance+" ";
for (i = 0; i < samples3.length; i++) {
	if (i == 0) {
		name = name + " samples "+ samples3[i];
	}
	if (i == samples3.length-1) {
		name = name + " and "+ samples3[i] + ".xls";
	}
	else {
		name = name + " , "+ samples3[i];
	}
}
if (lengthOf(name) > 149) {
	name = "summary of clonal analysis with distance "+distance+" .xls";
}

selectWindow("Summary tomato+ clones");
saveAs("Results", ImageFolder + name);
run("Close All");
selectWindow("Summary tomato+ clones2");
saveAs("Results", ImageFolder + "temp.xls");
run("Close");
open(ImageFolder + "temp.xls");
selectWindow("temp.xls");
allsamples = Table.getColumn("Sample");
//Table.get("Sample", 0);
mouse = newArray();
for (i = 0; i < allsamples.length; i++) {
	//allsamples[i] 
	tempsample = substring(allsamples[i] , 0, indexOf(allsamples[i], "-")+3);
	if( (occurencesInArray(mouse, tempsample) == 0) & (indexOf(allsamples[i], "-") != -1) ) {
		mouse = Array.concat(mouse, tempsample);
		//
	}
}
Array.print(mouse);
posmouse = newArray(); posmouse = Array.concat(posmouse,0);
n = 0;
for (j = 0; j < mouse.length; j++) {	
	for (i = n; i < allsamples.length; i++) {	
		if (indexOf(allsamples[i], mouse[j]) == -1) {
			posmouse = Array.concat(posmouse,i);	
			n = i+2;
			i = allsamples.length;
			
		}
	}
}

headings = split(Table.headings, "\t");
Array.print(headings);
Table.create("Summary tomato+ clones per mice");
selectWindow("Summary tomato+ clones per mice");
//IJ.renameResults("Results");
Table.setColumn("Mouse", mouse);
//Array with al the cathegories which should not include 0s
notZeros = newArray("average size of clones", "cells per clone", "cells per clone(with DAPI)", "watershed cells per clone", "watershed cells per clone (DAPI)");
for (k = 0; k < posmouse.length; k++) {
	selectWindow("temp.xls");
	valuestotal = Table.getColumn(headings[1]);
	if (k+1==posmouse.length)  {
		q = valuestotal.length;
	}
	else {
		q = posmouse[k+1];
	}
	selectWindow("Summary tomato+ clones per mice");
	Table.set("Number tumors", k , q-posmouse[k]);
	selectWindow("temp.xls");
	for (colum = 2; colum < headings.length; colum++) {
			selectWindow("temp.xls");
			valuestotal = Table.getColumn(headings[colum]);
			if (k+1==posmouse.length)  {
				q = valuestotal.length;
			}
			else {
				q = posmouse[k+1];
			}
			//print("This is k: " + k);
			//print("this is posmouse[k]+1: " + posmouse[k]+1);
		//	print("this is q: " + q);
			values = Array.slice(valuestotal,posmouse[k],q); 
			values2 = newArray();
			//loop to remove all Zeros whenever required
			for (m = 0; m < values.length; m++) {
				for (p = 0; p < notZeros.length; p++) {
					if( (headings[colum] == notZeros[p]) & (values[m] != 0)) {
						values2 = Array.concat(values2,values[m]);	
					}
					if(headings[colum] != notZeros[p]){
						values2 = Array.concat(values2,values[m]);	
					}
				}
			}
			if (headings[colum] == "total Epethilial Area") {
				totalcolumn2 = 0;
				for (n = 0; n < values2.length; n++) {
					totalcolumn2 = totalcolumn2+ values2[n];	
				}
			}
			if (headings[colum] == "total Area") {
				totalcolumn = 0;
				for (n = 0; n < values2.length; n++) {
					totalcolumn = totalcolumn+ values2[n];	
				}
			}
			if (headings[colum] == "Tom+ area"){
				totaltom = 0;
				for (n = 0; n < values2.length; n++) {
					totaltom = totaltom + values2[n];	
				}
				total = 100 *(totaltom/totalcolumn);
				totalEp = 100 * (totaltom/totalcolumn2);
			}
			if (headings[colum] == "number of clones"){
				number = 0;
				for (n = 0; n < values2.length; n++) {
					number = number + values2[n];	
				}
				totaln = (number/totalcolumn);
				totalEpn = (number/totalcolumn2);
			}
			
			Array.getStatistics(values2, min, max, mean, stdDev);
			selectWindow("Summary tomato+ clones per mice");
			Table.set(headings[colum], k, mean);
			if (colum == headings.length-1) {
				selectWindow("Summary tomato+ clones per mice");
				Table.set("TOTAL tom+/total_area", k, total);
				Table.set("TOTAL tom+/epethilial", k, totalEp);
				Table.set("TOTAL clones per area", k, totaln); Table.set("TOTAL clones per epethilial area", k, totalEpn);
			}

	}
}

selectWindow("Summary tomato+ clones per mice");
name2 = "summary of clonal analysis with distance "+distance+" per mice .xls";
saveAs("Results", ImageFolder + name2);

selectWindow("temp.xls");
run("Close");

File.delete(ImageFolder + "temp.xls");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("finished at : "+hour+ ":" + minute +":" + second);
//showMessage();
showMessage(" \t \t \t \t\t\t\t\t\t\t\t Done!", "Finished at : "+hour+ ":" + minute +":" + second);
setBatchMode(false);