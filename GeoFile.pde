class GeoFile
{
    boolean okFlag;
    String errMsg;
    JSONObject json;
    
    public GeoFile()
    {
        okFlag = true;
        errMsg = "";
        
        if (!openGFile())
        {
            okFlag = false;
            return;
        }
        
        if (!streetHasNoTinting(configInfo.layerName))
        {
            okFlag = false;
            return;
        }
    }
    
    boolean openGFile()
    {
        File file = new File(configInfo.readGFileName());
        if (!file.exists()) 
        {
            println(configInfo.readGFileName() + " does not exist - aborting");
            errMsg = configInfo.readGFileName() + " does not exist - aborting";
            return false;
        }
    
        // Open the file and load it   
        try
        {
            // load G* file
            json = loadJSONObject(configInfo.readGFileName());
        }
        catch(Exception e)
        {
            println(e);
            println("Fail to load street geo JSON file " + configInfo.readGFileName());
            errMsg = "Fail to load street geo JSON file " + configInfo.readGFileName();
            return false;
         }
         return true;
    }
    
    boolean streetHasNoTinting(String layerName)
    {
        
        // Check the file to see if it has tinting set or not
        // Read the street name
        streetName = Utils.readJSONString(json, "label", true);
    
        // Now chain down to get at the fields in the geo file               
        JSONObject dynamic = Utils.readJSONObject(json, "dynamic", true);
        if (dynamic == null)
        {
            // the dynamic level is sometimes missing ... so just set it to point at the original json object and continue on
            println("Reading geo file - dynamic is null " + configInfo.readGFileName());
            dynamic = json;
            if (dynamic == null)
            {
                // This should never happen as json should not be null at this point
                println("Reading geo file - unexpected error as reset dynamic pointer is null " + configInfo.readGFileName());
                errMsg = "Reading geo file - unexpected error as reset dynamic pointer is null " + configInfo.readGFileName();
                return false;
            }
        }
    
        // Now read in the desired layer
        JSONObject layers = Utils.readJSONObject(dynamic, "layers", true);
        
        if (layers == null)
        {
            // Error condition
            println("Error reading layers from " + configInfo.readGFileName());
            errMsg = "Error reading layers from " + configInfo.readGFileName() + " (" + errMsg + ")";
            return false; 
        }
    
        // Now chain through each of the layers contained here - checking the name as the actual layer name will be T_xxxxx
        int i;
        JSONObject myLayer = null;
        boolean found = false;
        List<String> layerList = new ArrayList(layers.keys());
        for (i = 0; i < layerList.size() && !found; i++)
        {
            myLayer = Utils.readJSONObject(layers, layerList.get(i), true);
            if (myLayer == null)
            {
                // Error condition
                println("Failed to read " + layerList.get(i) + " from " + configInfo.readGFileName());
                errMsg = "Failed to read " + layerList.get(i) + " from " + configInfo.readGFileName() + " (" + errMsg + ")";
                return false;
            }
            // Read the name of this layer
            String thisLayerName = Utils.readJSONString(myLayer, "name", true);
        
            if ((thisLayerName.length() > 0) && thisLayerName.equals(layerName))
            {
                // Found our matching layer
                found = true;
            }        
        }
        
        if (!found || myLayer == null)
        {
            // Error condition
            println("Error reading layer " + layerName + " from " + configInfo.readGFileName());
            errMsg = "Error reading layer " + layerName + " from " + configInfo.readGFileName();
            return false;
        }
        JSONObject filtersNEW = Utils.readJSONObject(myLayer, "filtersNEW", true);
        if (filtersNEW == null)
        {
            // Field is not present - therefore no tinting is present
            println("Success - No tinting information for layer " + layerName);
            return true;
        }
        
        int readVal;
        JSONObject filtersNewObject;
                                           
        filtersNewObject = Utils.readJSONObject(filtersNEW, "tintAmount", true);
        if (filtersNewObject != null)
        {                           
            readVal = Utils.readJSONInt(filtersNewObject, "value", true);
            if (readVal != 0)
            {
                println("Error - tint amount set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName());
                errMsg = "Error - tint amount set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName();
                return false;
            }
        }
    
        // Don't care about tint colour if the tint amount is 0 - as ignored so don't need to read
        filtersNewObject = Utils.readJSONObject(filtersNEW, "contrast", true);
        if (filtersNewObject != null)
        {                           
            readVal = Utils.readJSONInt(filtersNewObject, "value", true);
            if (readVal != 0)
            {
                println("Error - contrast set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName());
                errMsg = "Error - contrast set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName();
                return false;
            }
        }
        filtersNewObject = Utils.readJSONObject(filtersNEW, "saturation", true);
        if (filtersNewObject != null)
        {                           
            readVal = Utils.readJSONInt(filtersNewObject, "value", true);
            if (readVal != 0)
            {
                println("Error - saturation set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName());
                errMsg = "Error - saturation set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName();
                return false;
            }
        }
        filtersNewObject = Utils.readJSONObject(filtersNEW, "brightness", true);
        if (filtersNewObject != null)
        {                           
            readVal = Utils.readJSONInt(filtersNewObject, "value", true);
            if (readVal != 0)
            {
                println("Error - saturation set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName());
                errMsg = "Error - saturation set to " + readVal + " in " + layerName + " in " + configInfo.readGFileName();
                return false;
            }
        }
    
        // If reach here, then any values read in are set to 0
        return true;
    }
    
    public String readErrMsg()
    {
        return errMsg;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
}