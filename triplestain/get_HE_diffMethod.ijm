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

//convert to 32-bit
selectWindow("DecoB-(Colour_1)");
run("32-bit");
selectWindow("DecoA-(Colour_1)");
run("32-bit");

//calculate difference between the HE+stain1 and HE+stain2
//this should be stain1 and stain2
imageCalculator("Difference create", "DecoA-(Colour_1)","DecoB-(Colour_1)");
selectWindow("Result of DecoA-(Colour_1)");
rename("diffInv");
run("Invert");
//add HE+stain1 and HE+stain2
//this should be HE and both stains
imageCalculator("Add create", "DecoA-(Colour_1)","DecoB-(Colour_1)");
selectWindow("Result of DecoA-(Colour_1)");
rename("sum");
//remove the stains from HE+stains
imageCalculator("Subtract create", "sum","diffInv");
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