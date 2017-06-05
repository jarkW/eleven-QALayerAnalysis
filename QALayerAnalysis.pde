import java.text.DecimalFormat;
import java.io.FileWriter;
import java.io.*;
import java.util.List;
import processing.data.JSONObject;

// v0.1 uses Processing 3.3.4

// Allows me to find out what the colour is of the same pixel on a street snap and my snap
// NB Uses Processing co-ordinate system with 0,0 in top LH corner

// Config.json - including whether running with tints set??? Use one set of co-ords only
// configure search limits?
// Check that co-ords fit with gimp not game

ConfigInfo configInfo;
String workingDir = "";  // contains the config.json file

PImage refSnap;
PImage mySnap;

int snapScalingFactor;

int textBoxX;
int textBoxY;
int textBoxHeight;
int textBoxWidth;

int loopTextBoxX;
int loopTextBoxY;
int loopTextBoxHeight;
int loopTextBoxWidth;

ArrayList<PixelInfo> testPixels;
ColorSearch colorSearch;

String configFolderErrStr = "";

String streetName = "";

// Largely only used for reading in location of config file - otherwise just set the next action to 
// show need to end now.
boolean failNow = false;

PrintWriter output;
FileWriter fw;
BufferedWriter bw;

final static int BACKGROUND = #D6D6D6;
final static int RED_TEXT =  #FF002B;
final static int BLACK_TEXT = 0;

int loopCount = 0;

final static int USER_INPUT_CONFIG_FOLDER = 10;
final static int READ_CONFIG_FILE = 20;
final static int OPEN_OUTPUT_FILE = 30;
final static int READ_GFILE = 40;
final static int LOAD_REF_SNAP = 50;
final static int LOAD_MY_SNAP = 60;
final static int LOAD_PIXEL_VALUES = 70;
final static int INIT_SEARCH = 80;
final static int SEARCH_FOR_VALUES = 100;
final static int EXIT_NORMAL = 200;
final static int EXIT_ERROR = 300;
final static int IDLE = 1000;
int nextAction;

public void setup() 
{    
    // Set size of Processing window
    //size(1500, 1000);
    size(1200, 800);
    
    background(BACKGROUND);
    
    // Default the output text box for the case where error detected before street etc loaded
    textBoxX = 50;
    textBoxY = 50;
    textBoxHeight = height - 50;
    textBoxWidth = width - 50;
    
    if (!validConfigJSONLocation())
    {
        nextAction = USER_INPUT_CONFIG_FOLDER;
        selectInput("Select QALayerAnalysis_config.json in working folder:", "configJSONFileSelected");
    }
    else
    {
        nextAction = READ_CONFIG_FILE;
    }
}

public void draw()
{ 
    String s;
    String errMsg;
    
    //println("Next action = " + nextAction);    
    switch (nextAction)
    {
        case IDLE:
            // Do nothing
            break;
            
        case USER_INPUT_CONFIG_FOLDER:
            // Need to get user to input valid location of QALayerAnalysis_config.json
            // Come here whilst wait for user to select the input
            if (configFolderErrStr.length() > 0)
            {  
                nextAction = EXIT_ERROR;
            }
            else if (workingDir.length() > 0)
            {
                nextAction = READ_CONFIG_FILE;
            }
            break;
            
        case READ_CONFIG_FILE:
            // Set up config data
            configInfo = new ConfigInfo();
            if (!configInfo.readOkFlag())
            {
                // Error message already set up in this function
                displayError(configInfo.readErrMsg());
                nextAction = EXIT_ERROR;
            }
            else
            {
                nextAction = OPEN_OUTPUT_FILE;
            }
            break;
            
        case OPEN_OUTPUT_FILE:           
            // Set up output file
            if (!openOutputFile())
            {
                println("Error opening output file");
                displayError("Error opening output file");
                nextAction = EXIT_ERROR;
            }
            else
            {
                nextAction = READ_GFILE;
            }
            break;
            
        case READ_GFILE:
            // Load up the GFile and check to see that the layer requested has no tinting or anything
            GeoFile gFile = new GeoFile();
            if (!gFile.readOkFlag())
            {
                // Error message already set up in this function
                displayError(gFile.readErrMsg());
                nextAction = EXIT_ERROR;
            }
            else
            {
                nextAction = LOAD_REF_SNAP;
            }
            break;
            
        case LOAD_REF_SNAP:
            errMsg = loadSnap(true);
            if(errMsg.length() > 0)
            {
                println("Error opening reference snap " + configInfo.readSnapPath() + " " + errMsg);
                displayError("Error opening reference snap " + configInfo.readSnapPath() + " " + errMsg);
                nextAction = EXIT_ERROR;
            }
            else
            { 
                println(" Ref snap = " + refSnap.width);
                nextAction = LOAD_MY_SNAP;
            }
            break;
            
        case LOAD_MY_SNAP:
            errMsg = loadSnap(false);
            if(errMsg.length() > 0)
            {
                println("Error opening QA snap " + configInfo.readMySnapPath() + " " + errMsg);
                displayError("Error opening QA snap " + configInfo.readMySnapPath() + " " + errMsg);
                nextAction = EXIT_ERROR;
            }
            else if ((mySnap.width != refSnap.width) || (mySnap.height != refSnap.height))
            {
                println("Different sized snaps - check that " + configInfo.readMySnapPath() + " and " + configInfo.readSnapPath() + " refer to the same street");
                displayError("Different sized snaps - check that " + configInfo.readMySnapPath() + " and " + configInfo.readSnapPath() + " refer to the same street");
                nextAction = EXIT_ERROR;
            }
            else
            {
                nextAction = LOAD_PIXEL_VALUES;
            }
            break;
            
        case LOAD_PIXEL_VALUES:
            for (int i = 0; i < testPixels.size(); i++)
            {
                if (!testPixels.get(i).savePixelColors())
                {
                    println(testPixels.get(i).readErrMsg());
                    displayError(testPixels.get(i).readErrMsg());
                    nextAction = EXIT_ERROR;
                    return;
                }
            }
            nextAction = INIT_SEARCH;
            break;
            
        case INIT_SEARCH:           
            // Set up search structures
            colorSearch = new ColorSearch();
            
            // print starting RGB etc to file/screen
            setupDisplayVars();
            printHeaderInfo();
            nextAction = SEARCH_FOR_VALUES;
            break;
            
        case SEARCH_FOR_VALUES:
            if (loopCount > configInfo.readEndLoopCondition())
            {
                if (colorSearch.noBetterValuesFound())
                {
                    printLine("Exiting - no more entries found");
                    s = colorSearch.getFinalSolution();
                    printLine(s);
                    println(s);
                    nextAction = EXIT_NORMAL;
                }
                // else - will return to this leg next time around and continue to check until no better nearby entries found
            }
            else
            {            
                if (loopCount % 100 == 0)
                {
                    showLoopCount();                
                }              
                if (colorSearch.foundRGBCombination())
                {
                    printLine("Exiting - found good match");
                    s = colorSearch.getFinalSolution();
                    printLine(s);
                    println(s);
                    nextAction = EXIT_NORMAL;                   
                }
            }
            loopCount++;
            break;
            
        case EXIT_NORMAL:
            // No errors so just shut window
            
            // Output final result to screen and file and wait for user to close file
            println("Normal termination");
            
            // Write this out in the space where the loop count has been recorded
            textBoxX = loopTextBoxX;          
            textBoxY = loopTextBoxY;
            textBoxWidth = loopTextBoxWidth;
            textBoxHeight = loopTextBoxHeight;
            displayInfo("Normal termination - press q, x or ESC to close window", false);
            nextAction = IDLE;
            break;
            
        case EXIT_ERROR:
            // Just idle - user can close screen when read message
            println("Exiting after error");
            if (configFolderErrStr.length() > 0)
            {
                displayError(configFolderErrStr);
            }
            nextAction = IDLE;
            break;
            
        default:
            println("Unexpected next action " + nextAction);
      
            nextAction = EXIT_ERROR;
            break;
    }
}

void displayError(String msg)
{   
    fill(RED_TEXT);
    textSize(14);
    text(msg, textBoxX+ 10, textBoxY + 10, textBoxWidth - 20, textBoxHeight); 
    textBoxY += 50;
    textBoxHeight -= 50;  
}

void displayInfo(String msg, boolean overwrite)
{
    fill(BACKGROUND);
    stroke(BACKGROUND);
    rect(textBoxX, textBoxY, textBoxWidth, textBoxHeight); 


    // Write out value 
    fill(BLACK_TEXT);
    textSize(12);
    text(msg, textBoxX + 10, textBoxY + 10, textBoxWidth - 20, textBoxHeight);  // Text wraps within text box
    
    if (!overwrite)
    {
        // change box parameters so keep this line visible next time something is output to the screen
        textBoxY += 50;
        textBoxHeight -= 50;  
        loopTextBoxY += 50;
    }
}

boolean openOutputFile()
{
    // open the file ready for writing    
    try 
    {
        File file =new File(configInfo.outputFile);
 
        if (!file.exists()) 
        {
          file.createNewFile();
        }
 
        FileWriter fw = new FileWriter(file, true);///true = append
        BufferedWriter bw = new BufferedWriter(fw);
        output = new PrintWriter(bw);
    }
    catch(IOException ioe) 
    {
        System.out.println("Exception ");
        ioe.printStackTrace();
        return false;
    }
    
    return true;
}

String loadSnap(boolean useRefSnap)
{
    String errMsg = "";
    File file;
    String fName;
    
    if (useRefSnap)
    {
        fName = configInfo.readSnapPath();
    }
    else
    {
        fName = configInfo.readMySnapPath();
    }
    
    // Load up this snap image
    file = new File(fName);
    if (!file.exists())
    {
        println("Missing file - " + fName);
        errMsg = "Missing file - " + fName;
        return errMsg;
    }
            
    try
    {
        // load image
        if (useRefSnap)
        {
            refSnap = loadImage(fName, "png");
        }
        else
        {
            mySnap = loadImage(fName, "png");
        }
    }
    catch(Exception e)
    {
        println(e);
        println("Fail to load image for " + fName);
        errMsg = "Fail to load image for " + fName;
        return errMsg;
    }         
    try
    {
        // load image pixels
        if (useRefSnap)
        {
            refSnap.loadPixels();
        }
        else
        {
            mySnap.loadPixels();
        }
    }
    catch(Exception e)
    {
        println(e);
        println("Fail to load image pixels for " + fName);
        errMsg = "Fail to load image pixels for " + fName;
        return errMsg;
    } 
    return errMsg;
}

void setupDisplayVars()
{
    // If street is wide, then place at bottom of screen. If tall then set to LHS
    
    // Need to calculate the scaling factor to make it fit in the window
    if (refSnap.width > refSnap.height)
    {
        println("Width " + refSnap.width + " is greater than height " + refSnap.height);
        println("Image placed at x,y 0," + int(height - (refSnap.height*width/refSnap.width)) + " with width " + int(width) + " and height " + int(refSnap.height*width/refSnap.width));
        // Makes sure the snap fits across the screen
        image(refSnap, 0, height - (refSnap.height*width/refSnap.width), width, refSnap.height*width/refSnap.width);
        
        // Set up text to be on part of screen not occupied by snap
        textBoxX = 50;
        textBoxY = 50;
        //textBoxHeight = height - (height*width/refSnap.width) - 50;
        textBoxHeight = 100;
        textBoxWidth = width - 50;
        
        loopTextBoxX = textBoxX;
        loopTextBoxY = textBoxY + textBoxHeight;
        loopTextBoxWidth = textBoxWidth;
        loopTextBoxHeight = 50;
    }
    else
    {
        // Have tall, narrow street
        println("Width " + refSnap.width + " is less than/equal height " + refSnap.height);
        println("Image placed at x,y 0,0" + " with width " + int(refSnap.width*height/refSnap.height) + " and height " + int(height));
        image(refSnap, 0, 0, refSnap.width*height/refSnap.height, height);
        // Set up text to be on part of screen not occupied by snap
        textBoxX = (refSnap.width*height/refSnap.height) + 50;
        textBoxY = 50;
        //textBoxHeight = height - 50;
        textBoxHeight = 100;
        
        textBoxWidth = width - (width*height/refSnap.height) - 50;   
        
        loopTextBoxX = textBoxX;
        loopTextBoxY = textBoxY + textBoxHeight;
        loopTextBoxWidth = textBoxWidth;
        loopTextBoxHeight = 50;
    }
    
    // Clear text box - i.e. fill with background colour
    fill(BACKGROUND);
    stroke(BACKGROUND);
    rect(textBoxX, textBoxY, textBoxWidth, textBoxHeight);
}

void keyPressed() 
{
    if ((key == 'x') || (key == 'X') || (key == 'q') || (key == 'Q'))
    {
        exit();
    }
    // Make sure ESC closes window cleanly - and closes window
    else if (key==27)
    {
        key = 0;
        exit();
    }
}

public void printLine(String s)
{
    println(s);
    output.println(s);
    output.flush();
}

void showLoopCount()
{
    fill(BACKGROUND);
    stroke(BACKGROUND);
    rect(loopTextBoxX, loopTextBoxY, loopTextBoxWidth, loopTextBoxHeight);
    
    fill(BLACK_TEXT);
    textSize(12);
    String s;
    if (configInfo.readDebugFlag())
    {
        s = "Loop count = " + loopCount + " guessFactor = " + colorSearch.guessFactor;
    }
    else
    {
       s = loopCount + " iterations ...";
    }
    text(s, loopTextBoxX, loopTextBoxY, loopTextBoxWidth, loopTextBoxHeight);  // Text wraps within text box    
}

void printHeaderInfo()
{
    // Put header in the output file
    String s;
    printLine("");
    printLine(" **************************************************************************************************************************************");
    s = "Analysing layer " + configInfo.readLayerName() + " for street " + streetName; 
    if (configInfo.readDebugFlag())
    {
        s = s + " using guessFactor=" + colorSearch.guessFactor + " guessFactorDecrement=" + colorSearch.guessFactorDecrement + " guessFactorMultiplier=" + colorSearch.guessFactorMultiplier + " reset after " + colorSearch.idleLoopCondition;
    }
    s = s + " ending after " + configInfo.readEndLoopCondition() + " iterations"; 
    printLine(s);
    fill(BLACK_TEXT);
    textSize(12);
    displayInfo(s, false);
    for (int i = 0; i < testPixels.size(); i++)
    {
        s = testPixels.get(i).getOrigInfo();
        printLine(s);
        displayInfo(s, false);
    }
    printLine(" **************************************************************************************************************************************");
    println("");
}

boolean validConfigJSONLocation()
{
    // Searches for the configLocation.txt file which contains the saved location of the QABot_config.json file
    // That location is returned by this function.
    String  configLocation = "";
    File file = new File(sketchPath("configLocation.txt"));
    if (!file.exists())
    {
        return false;
    }
    
    // File exists - now validate
    //Read contents - first line is QABot_config.json location
    String [] configFileContents = loadStrings(sketchPath("configLocation.txt"));
    configLocation = configFileContents[0];
    
    // Have read in location - check it exists
    if (configLocation.length() > 0)
    {        
        file = new File(configLocation + File.separatorChar + "QALayerAnalysis_config.json");
        if (!file.exists())
        {
            println("Missing QALayerAnalysis_config.json file from ", configLocation);
            return false;
        }
    }
    workingDir = configLocation;  
    return true;
    
}

void configJSONFileSelected(File selection)
{
    if (selection == null) 
    {
        configFolderErrStr = "Window was closed or the user hit cancel";
        return;
    }      
    else 
    {
        println("User selected " + selection.getAbsolutePath());

        // Check that not selected QALayerAnalysis_config.json.txt which might look like QALayerAnalysis_config.json in the picker (as not seeing file suffixes for known file types on PC)
        if (!selection.getAbsolutePath().endsWith("QALayerAnalysis_config.json"))
        {
            configFolderErrStr = "Please select a QALayerAnalysis_config.json file (check does not have hidden .txt ending)";
            return;
        }
        
        // User selected correct file name so now save
        String[] list = new String[1];
        // Strip out QALayerAnalysis_config.json part of name - to just get folder name
        list[0] = selection.getAbsolutePath().replace(File.separatorChar + "QALayerAnalysis_config.json", "");
        try
        {
            saveStrings(sketchPath("configLocation.txt"), list);
        }
        catch (Exception e)
        {
            println(e);
            configFolderErrStr = "Error detected saving QALayerAnalysis_config.json location to configLocation.txt in program directory";
            return;
        }
        workingDir = list[0];
    }
}

class PixelInfo
{   
    int x;
    int y;
    float snapR;
    float snapG;
    float snapB;
    float snapA; // Or is this always 255 so ignore???
    color snapColor;

    float myR;
    float myG;
    float myB;
    float myA; // Or is this always 255 so ignore???
    color myColor;
    
    float origDeltaRGB;
    float workingDeltaRGB;
    
    String errMsg;
    
    public PixelInfo(int X, int Y)
    {
        x = X;
        y = Y;       
        origDeltaRGB = 0;
        workingDeltaRGB = 0;
    }
    
    boolean savePixelColors()
    {
        // At this point we can validate the x,y passed in - couldn't do this until loaded the snaps
        if (x < 0 || x > refSnap.width)
        {
            errMsg = "For the x,y pair " + x + "," + y + " x is outside the snap range of 0 to " + refSnap.width;
            return false;
        }
        if (y < 0 || y > refSnap.height)
        {
            errMsg = "For the x,y pair " + x + "," + y + " y is outside the snap range of 0 to " + refSnap.height;
            return false;
        }
        
        int loc = x + (y * refSnap.width);
        snapColor = refSnap.pixels[loc];
        myColor = mySnap.pixels[loc];
        
        snapR = red(snapColor);
        snapG = green(snapColor);
        snapB = blue(snapColor);
        snapA = 255;
        myR = red(myColor);
        myG = green(myColor);
        myB = blue(myColor);
        myA = 255;
        
        origDeltaRGB = abs(snapR-myR) + abs(snapG-myG) + abs(snapB-myB);
        return true;
    }
    
    String getOrigInfo()
    {
        colorMode(HSB, 360, 100, 100);
        String s = "ORIGINAL (x,y=" + x + "," + y + ") Ref snap RGB=" + int(snapR) + ":" + int(snapG) + ":" + int(snapB) + "HSV=" + int(hue(snapColor)) + ":" + int(saturation(snapColor)) + ":" + int(brightness(snapColor)) + " 0x" + hex(snapColor, 6);
        s = s + "(x,y=" + x + "," + y + ") QA snap RGB=" + int(myR) + ":" + int(myG) + ":" + int(myB) + "HSV=" + int(hue(myColor)) + ":" + int(saturation(myColor)) + ":" + int(brightness(myColor)) + " 0x" + hex(myColor, 6);     
        s = s + "   Delta RGB=" + int(origDeltaRGB);
        colorMode(RGB, 255, 255, 255);
        return s;
    }   
    
    int readX()
    {
        return x;
    }
    
    int readY()
    {
        return y;
    }
    
    float readWorkingDeltaRGB()
    {
        return workingDeltaRGB;
    }
    
    void setWorkingDeltaRGB(float delta)
    {
        workingDeltaRGB = delta;
    }
    
    String readErrMsg()
    {
        return errMsg;
    }

}