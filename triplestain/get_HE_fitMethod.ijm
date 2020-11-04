close("\\Others");
original = getTitle();

// Do deconvolutions A and B
stain_vecsA = newArray(237, 255, 143, 255, 44,  3, 1, 31, 255);
stain_vecsB = newArray(237, 254, 118,  55,255,105, 0, 38, 255);
maxTileSize = 2000;		//maximum StarDist tile size
probabilityThreshold = 0.3;

//A
rename("DecoA");
run("Colour Deconvolution", "vectors=[User values] [r1]="+stain_vecsA[0]+" [g1]="+stain_vecsA[1]+" [b1]="+stain_vecsA[2]+" [r2]="+stain_vecsA[3]+" [g2]="+stain_vecsA[4]+" [b2]="+stain_vecsA[5]+" [r3]="+stain_vecsA[6]+" [g3]="+stain_vecsA[7]+" [b3]="+stain_vecsA[8]);

//B
selectWindow("DecoA");
rename("DecoB");
run("Colour Deconvolution", "vectors=[User values] [r1]="+stain_vecsB[0]+" [g1]="+stain_vecsB[1]+" [b1]="+stain_vecsB[2]+" [r2]="+stain_vecsB[3]+" [g2]="+stain_vecsB[4]+" [b2]="+stain_vecsB[5]+" [r3]="+stain_vecsB[6]+" [g3]="+stain_vecsB[7]+" [b3]="+stain_vecsB[8]);
selectWindow("DecoB");
rename(original);

// Remove stain from HE 2x
stain = "DecoA-(Colour_2)";
HE_and_stain = "DecoB-(Colour_1)";
remove_leakthrough(stain, HE_and_stain,"HE1")
stain = "DecoB-(Colour_2)";
HE_and_stain = "DecoA-(Colour_1)";
remove_leakthrough(stain, HE_and_stain,"HE2")
// Calculate average
imageCalculator("Average create", "HE1","HE2");
haematoxylin_image = "Haematoxylin_only"
rename(haematoxylin_image);

//StarDist
run("RGB Color");
run("Make Composite");

//Calc max tiles
getDimensions(width, height, channels, slices, frames);
starDistTiles = pow(floor(maxOf(width, height)/maxTileSize)+1,2);	//Determine the nr. of tiles
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'"+haematoxylin_image+"', 'modelChoice':'Versatile (H&E nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'"+probabilityThreshold+"', 'nmsThresh':'0.3', 'outputType':'Both', 'nTiles':'"+starDistTiles+"', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
selectWindow("Label Image");
roiManager("Show All");
roiManager("Set Color", "gray");
roiManager("Set Line Width", 0);
roiManager("Show All");

function remove_leakthrough(stain, HE_and_stain,outname){
	roiManager("reset");
	run("Select None");
	selectWindow(HE_and_stain);
	run("Invert");
	selectWindow(stain);
	run("Invert");
	setAutoThreshold("MaxEntropy dark");
	run("Create Selection");
	resetThreshold();
	Roi.getContainedPoints(xpoints, ypoints);
	roiManager("add");
	run("Select None");
	roiManager("Show All without Labels");
	
	setBatchMode(true);
	stainPixels = newArray(xpoints.length);
	HE_and_stainPixels = newArray(xpoints.length);
	n=0;
	for (i=0 ; i<xpoints.length ; i++) {
		selectWindow(stain);
		stainPixels[n] = getPixel(xpoints[i], ypoints[i]);
		selectWindow(HE_and_stain);
		HE_and_stainPixels[n] = getPixel(xpoints[i], ypoints[i]);
		if(maxOf(stainPixels[n],HE_and_stainPixels[i]) < 255) n++;	//Check if any of the pixels is 255
	}
	setBatchMode(false);
	stainPixels = Array.trim(stainPixels, n);
	HE_and_stainPixels = Array.trim(HE_and_stainPixels, n);
	
	Fit.doFit("Straight line", stainPixels, HE_and_stainPixels);
	Fit.plot();
	Plot.setStyle(1, "red,none,1.0,Dot");
	print("offset:"+Fit.p(0));
	print("slope:"+Fit.p(1));
	print("R-squared: "+Fit.rSquared);
	
	selectWindow(stain);
	run("Duplicate...", "title=temp");
	run("Multiply...", "value="+Fit.p(1));
	
	imageCalculator("Subtract create", HE_and_stain, "temp");
	rename(outname);
	close("temp");
	run("Invert");
	selectWindow(HE_and_stain);
	run("Invert");
	selectWindow(stain);
	run("Invert");
}