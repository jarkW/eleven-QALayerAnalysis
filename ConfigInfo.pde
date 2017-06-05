class ConfigInfo {
    
    boolean okFlag;
    String errMsg;
    
    String snapPath;
    String mySnapPath;
    String outputFile;
    String GFileName;
    int endLoopCondition;
    String layerName;
    //boolean updateGFile; Not yet implemented
    boolean debugFlag;  

    // constructor/initialise fields
    public ConfigInfo()
    {
        okFlag = true;
        errMsg = "";
                   
        // Read in config info from JSON file
        if (!readConfigData())
        {
            println("Error in readConfigData");
            okFlag = false;
            return;
        }      
    }  
     
    boolean readConfigData()
    {
        JSONObject json;
        File myDir;
        File file;
        
        // Open the config file
        file = new File(workingDir + File.separatorChar + "QALayerAnalysis_config.json");
        if (!file.exists())
        {
            println("Missing QALayerAnalysis_config.json file from ", workingDir);
            errMsg = "Missing QALayerAnalysis_config.json file from " + workingDir;
            return false;
        }
        else
        {
            println("Using QALayerAnalysis_config.json file in ", workingDir);
        }
        
        try
        {
            // Read in stuff from the config file
            json = loadJSONObject(workingDir + File.separatorChar + "QALayerAnalysis_config.json"); 
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to load QALayerAnalysis_config.json file - check file is correctly formatted by pasting contents into http://jsonlint.com/");
            errMsg = "Failed to load QALayerAnalysis_config.json file - check file is correctly formatted by pasting contents into http://jsonlint.com/";
            return false;
        }
        
        // Now read in the different fields
        snapPath = Utils.readJSONString(json, "reference_snap", true); 
        if (!Utils.readOkFlag() || snapPath.length() == 0)
        {
            // Error message already set by called function
            errMsg = Utils.readErrMsg();
            return false;
        }
 
        mySnapPath = Utils.readJSONString(json, "QA_snap", true); 
        if (!Utils.readOkFlag() || mySnapPath.length() == 0)
        {
            // Error message already set by called function
            errMsg = Utils.readErrMsg();
            return false;
        }
        
        outputFile = Utils.readJSONString(json, "output_file", false); 
        if (outputFile.length() == 0)
        {
            // Default to output.txt in the Processing directory - but tell user
            outputFile = sketchPath("output.txt");
            displayError("Missing output_file field in QALayerAnalysis_config.json file - defaulting to " + outputFile);
        }       
     
        GFileName = Utils.readJSONString(json, "street_G_file", true); 
        if (!Utils.readOkFlag() || mySnapPath.length() == 0)
        {
            // Error message already set by called function
            errMsg = Utils.readErrMsg();
            return false;
        }  
        
        layerName = Utils.readJSONString(json, "layer_name", true); 
        if (!Utils.readOkFlag() || layerName.length() == 0)
        {
            // Error message already set by called function
            errMsg = Utils.readErrMsg();
            return false;
        }
        
        // read in pixels
        JSONArray pixelXYArray = Utils.readJSONArray(json, "pixel_coordinates", true); 
        if (!Utils.readOkFlag() || pixelXYArray == null)
        {
            // Error message already set by called function
            errMsg = Utils.readErrMsg();
            return false;
        }
        
        // Now read in the pairs of x,y co-ordinates
        testPixels = new ArrayList<PixelInfo>();
        for (int i = 0; i < pixelXYArray.size(); i++)
        {
            JSONArray XYArray = Utils.readJSONArrayFromJSONArray(pixelXYArray, i, true); 
            if (!Utils.readOkFlag() || XYArray == null)
            {
                // Error message already set by called function
                errMsg = "Problem reading x,y pair at index " + i + " " + Utils.readErrMsg();
                return false;
            }
            
            int x = Utils.readIntFromJSONArray(XYArray, 0, true);
            if (!Utils.readOkFlag())
            {
                errMsg = "Problem reading x value at index " + i + " " + Utils.readErrMsg();
                return false;
            }
            int y = Utils.readIntFromJSONArray(XYArray, 1, true);
            if (!Utils.readOkFlag())
            {
                errMsg = "Problem reading y value at index " + i + " " + Utils.readErrMsg();
                return false;
            }
            
            // Now create an entry for these co-ordinates
            testPixels.add(new PixelInfo(x, y));
            println("Adding entry for x,y=" + x + "," + y);
        }
        
        endLoopCondition = Utils.readJSONInt(json, "maximum_tries", false); 
        if (endLoopCondition == 0)
        {
            // Default to 30000 - but tell user
            endLoopCondition = 30000;
            displayError("This programme will give up after trying " + endLoopCondition + " different colour combinations");
        }       

        // If this is missing, then defaults to false - for my use only
        debugFlag = Utils.readJSONBool(json, "debug_flag", false); 
                   
        // Everything OK
        return true;
    }
  
    public String readSnapPath()
    {
        return snapPath;
    }
    
    public String readMySnapPath()
    {
        return mySnapPath;
    }
    
    public String readOutputFile()
    {
        return outputFile;
    }

    public String readGFileName()
    {
        return GFileName;
    }
    
    public String readLayerName()
    {
        return layerName;
    }
    
    public boolean readDebugFlag()
    {
        return debugFlag;
    }  

    public boolean readOkFlag()
    {
        return okFlag;
    }
    
    public String readErrMsg()
    {
        return errMsg;
    }
    
    public int readEndLoopCondition()
    {
        return endLoopCondition;
    }
}