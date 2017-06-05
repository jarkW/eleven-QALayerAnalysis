class ColorSearch
{
    boolean okFlag;
    ColorInfo bestRGBValues;
    ColorInfo RGBValues;  

    final static float MAX_GUESS_FACTOR = 10.0; //10.0
    float guessFactor;
    float guessFactorDecrement;
    float guessFactorMultiplier; 
    int idleLoopCondition;  // jump to another set of RGB once not found a better match this many times
    boolean resetGuessFactorFlag;
    int idleCount;
    int guessFactorMinCount;
    
    ColorMatrix cm;
    
    DecimalFormat df = new DecimalFormat("#.##"); 
    
    // constructor/initialise fields
    public ColorSearch()
    {
        okFlag = true;
        guessFactor = MAX_GUESS_FACTOR;
        guessFactorDecrement = 0.1;
        guessFactorMultiplier = 0.999; //0.99
        idleLoopCondition = 5000;  // jump to another set of RGB once not found a better match this many times
        resetGuessFactorFlag = false;   
        idleCount = 0;
        guessFactorMinCount = 0;
        
        
        // Initialise structures to grey (not needed really for RGBValues as will be set up later)
        bestRGBValues = new ColorInfo(128, 128, 128, 255, 50, 0, 0, 0);        
        RGBValues = new ColorInfo(128, 128, 128, 255, 50, 0, 0, 0);              
    }
    
    public boolean foundRGBCombination()
    {
        //if (idleCount == 0 && loopCount > 1)
        if (resetGuessFactorFlag)
        {
            // Are resetting the RGB values to random values        
            // Generate 7 random increments          
            printLine("Generate random RGB");
            RGBValues.r = random(0, 256);
            RGBValues.g = random(0, 256);
            RGBValues.b = random(0, 256);
            //a = addRandomIncrement(bestA, guessFactor*random(-1, 1), 0, 255);
            RGBValues.a = 255;
            RGBValues.col = color(RGBValues.r, RGBValues.g, RGBValues.b, RGBValues.a);
            RGBValues.saturation = int(random(-100, 101));
            RGBValues.brightness = int(random(-100, 101));
            RGBValues.contrast = int(random(-100, 101));
            RGBValues.tintAmount = int(random(0, 101));
            resetGuessFactorFlag = false;
        }
        else
        {       
            // Generate 7 random increments
            RGBValues.r = addRandomIncrement(bestRGBValues.r, guessFactor*random(-1, 1), 0, 255);
            RGBValues.g = addRandomIncrement(bestRGBValues.g, guessFactor*random(-1, 1), 0, 255);
            RGBValues.b = addRandomIncrement(bestRGBValues.b, guessFactor*random(-1, 1), 0, 255);
            //a = addRandomIncrement(bestA, guessFactor*random(-1, 1), 0, 255);
            RGBValues.a = 255;
            RGBValues.col = color(RGBValues.r, RGBValues.g, RGBValues.b, RGBValues.a);
            RGBValues.saturation = int(addRandomIncrement(float(bestRGBValues.saturation), guessFactor*random(-1, 1), -100, 100));
            RGBValues.brightness = int(addRandomIncrement(float(bestRGBValues.brightness), guessFactor*random(-1, 1), -100, 100));
            RGBValues.contrast = int(addRandomIncrement(float(bestRGBValues.contrast), guessFactor*random(-1, 1), -100, 100));
            RGBValues.tintAmount = int(addRandomIncrement(float(bestRGBValues.tintAmount), guessFactor*random(-1, 1), 0, 100));
        }

        // Use these to create a new color matrix
        cm = new ColorMatrix(RGBValues.col, RGBValues.tintAmount, RGBValues.contrast, RGBValues.saturation, RGBValues.brightness);
        float deltaRGB = 0;
        for (int i=0; i <testPixels.size(); i++)
        {
            cm.calcNewRPGA(testPixels.get(i).myR, testPixels.get(i).myG, testPixels.get(i).myB, testPixels.get(i).myA);
            
            // Diff the RGB of this new colour against the reference
            float thisDeltaRGB = abs(testPixels.get(i).snapR-cm.newR) + abs(testPixels.get(i).snapB-cm.newB) + abs(testPixels.get(i).snapG-cm.newG) + abs(testPixels.get(i).snapA-cm.newA);
            
            // Save the RGB in case we end up printing it
            testPixels.get(i).setWorkingDeltaRGB(thisDeltaRGB);
            
            // Increment the deltaRGB
            deltaRGB += thisDeltaRGB;
            
        }
        // do average
        deltaRGB = deltaRGB/testPixels.size();
        //println(loopCount + " (delta=" + df.format(deltaRGB) + ")      RGBA " + int(r) + ":" + int(g) + ":" + int(b) + ":" + int(a) + " % SBC = " + tintAmount + ":" + saturation + ":" + brightness + ":" + contrast);
        
        // Now see if this is a better match than the previous time
        
        if ((bestRGBValues.deltaRGB == -1) || (deltaRGB < bestRGBValues.deltaRGB))
        {
            // First time through OR found a better match than that saved
            // Save the information
            bestRGBValues.deltaRGB = deltaRGB;
            bestRGBValues.r = RGBValues.r;
            bestRGBValues.g = RGBValues.g;
            bestRGBValues.b = RGBValues.b;
            bestRGBValues.a = RGBValues.a;
            bestRGBValues.saturation = RGBValues.saturation;
            bestRGBValues.brightness = RGBValues.brightness;
            bestRGBValues.contrast = RGBValues.contrast;
            bestRGBValues.tintAmount = RGBValues.tintAmount;
                        
            // Write to screen           
            String s = bestRGBValues.getColorInfo();  
            displayInfo(s, true);
            
            // write to file
            printLine(s);           
            println(s);
            
            if (deltaRGB <= 1)
            {
                printLine("Found perfect match - exiting");
                return true;
            }
            
            // Decrease the guessFactor ... 
            //if (guessFactor > 1.0)
            //if (guessFactor > guessFactorDecrement)
            //{
            //    guessFactor -= guessFactorDecrement;
            //}
            
            // This exponential decrease is better than a linear one
            if (guessFactor > 1.0)
            {
                guessFactor = guessFactor * guessFactorMultiplier;
            }
            
            // Reset idlecount
            idleCount = 0;
        }
        // else - is worse match so leave the best values untouched for now
        else
        {
            if (guessFactor > 1.0)
            {
                guessFactor = guessFactor * guessFactorMultiplier;
            }
            else
            {
                guessFactorMinCount++;
            }
            idleCount++;
            
            if (idleCount > idleLoopCondition || guessFactorMinCount > 500)
            {
                // Just check that there are no more better options close by
                // May end up returning here several times before then deciding that
                // the best values we have are at the local minima
                if (noBetterValuesFound())
                {
                    // reset the guessFactor so can try somewhere else
                    println(loopCount + " : RESETTING GUESS FACTOR BACK TO " + MAX_GUESS_FACTOR);
                    guessFactor = MAX_GUESS_FACTOR;
                    idleCount = 0;
                    guessFactorMinCount = 0;
                    resetGuessFactorFlag = true;
                }
            }
        }
        
        return false;
    }
    
    
    float addRandomIncrement(float value, float incr, int minValue, int maxValue)
    {
        float newValue;
        newValue = value + int(incr);
        if (newValue > maxValue)
        {
            newValue = maxValue;
        }
        else if (newValue < minValue)
        {
            newValue = minValue;
        }
        
        return newValue;
    }
    
    public boolean noBetterValuesFound()
    {
        // Takes the best RGB values and loops through trying each of the values +/- 1 to see if get a slightly better result. 
        color col;
        float deltaRGB;
       
        // Increment R
        col = color(constrain(bestRGBValues.r+1, 0, 255), bestRGBValues.g, bestRGBValues.b, bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.r = bestRGBValues.r + 1;
            println("Tweaked R by +1 to " + bestRGBValues.r);
            return false;
        }
        col = color(constrain(bestRGBValues.r-1, 0, 255), bestRGBValues.g, bestRGBValues.b, bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.r = bestRGBValues.r - 1;
            println("Tweaked R by -1 to " + bestRGBValues.r);
            return false;
        }
        
        // Increment G
        col = color(bestRGBValues.r, constrain(bestRGBValues.g+1, 0, 255), bestRGBValues.b, bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.g = bestRGBValues.g + 1;
            println("Tweaked G by +1 to " + bestRGBValues.g);
            return false;
        }
        col = color(bestRGBValues.r, constrain(bestRGBValues.g-1, 0, 255), bestRGBValues.b, bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.g = bestRGBValues.g - 1;
            println("Tweaked G by -1 to " + bestRGBValues.g);
            return false;
        }
        
        // Increment B
        col = color(bestRGBValues.r, bestRGBValues.g, constrain(bestRGBValues.b+1, 0, 255), bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.b = bestRGBValues.b + 1;
            println("Tweaked B by +1 to " + bestRGBValues.b);
            return false;
        }
        col = color(bestRGBValues.r, bestRGBValues.g, constrain(bestRGBValues.b-1, 0, 255), bestRGBValues.a);
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.b = bestRGBValues.b - 1;
            println("Tweaked B by -1 to " + bestRGBValues.b);
            return false;
        }
        
        // Leave A as 255;
        col = color(bestRGBValues.r, bestRGBValues.g, bestRGBValues.b, bestRGBValues.a);
        
        // Increment tintAmount
        deltaRGB = calcDeltaRGB(col, constrain(bestRGBValues.tintAmount+1, 0, 100), bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.tintAmount = bestRGBValues.tintAmount + 1;
            println("Tweaked bestRGBValues.tintAmount by +1 to " + bestRGBValues.tintAmount);
            return false;
        }
        deltaRGB = calcDeltaRGB(col, constrain(bestRGBValues.tintAmount-1, 0, 100), bestRGBValues.contrast, bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.tintAmount = bestRGBValues.tintAmount - 1;
            println("Tweaked bestRGBValues.tintAmount by -1 to " + bestRGBValues.tintAmount);
            return false;
        }
        
        // Increment bestRGBValues.contrast
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, constrain(bestRGBValues.contrast+1, -100, 100), bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.contrast = bestRGBValues.contrast + 1;
            println("Tweaked bestRGBValues.contrast by +1 to " + bestRGBValues.contrast);
            return false;
        }
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, constrain(bestRGBValues.contrast-1, -100, 100), bestRGBValues.saturation, bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.contrast = bestRGBValues.contrast - 1;
            println("Tweaked bestRGBValues.contrast by -1 to " + bestRGBValues.contrast);
            return false;
        }
        
        // Increment bestRGBValues.saturation
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, constrain(bestRGBValues.saturation+1, -100, 100), bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.saturation = bestRGBValues.saturation + 1;
            println("Tweaked bestRGBValues.saturation by +1 to " + bestRGBValues.saturation);
            return false;
        }    
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, constrain(bestRGBValues.saturation-1, -100, 100), bestRGBValues.brightness);
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.saturation = bestRGBValues.saturation - 1;
            println("Tweaked bestRGBValues.saturation by -1 to " + bestRGBValues.saturation);
            return false;
        }
        
        // Increment bestRGBValues.brightness
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, constrain(bestRGBValues.brightness+1, -100, 100));
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.brightness = bestRGBValues.brightness + 1;
            println("Tweaked bestRGBValues.brightness by +1 to " + bestRGBValues.brightness);
            return false;
        }
        deltaRGB = calcDeltaRGB(col, bestRGBValues.tintAmount, bestRGBValues.contrast, bestRGBValues.saturation, constrain(bestRGBValues.brightness-1, -100, 100));
        if (deltaRGB < bestRGBValues.deltaRGB)
        {
            // Found a better match, so save
            bestRGBValues.brightness = bestRGBValues.brightness - 1;
            println("Tweaked bestRGBValues.brightness by -1 to " + bestRGBValues.brightness);
            return false;
        }
       
        // If reach here, then no better values were found
        return true;    
    }

    float calcDeltaRGB(color col, int tintAmount, int contrast, int saturation, int brightness)
    {
        ColorMatrix cm = new ColorMatrix(col, tintAmount, contrast, saturation, brightness);
        float deltaRGB = 0;
        
        for (int i=0; i <testPixels.size(); i++)
        {
            cm.calcNewRPGA(testPixels.get(i).myR, testPixels.get(i).myG, testPixels.get(i).myB, testPixels.get(i).myA);
                
            // Diff the RGB of this new colour against the reference
            deltaRGB += abs(testPixels.get(i).snapR-cm.newR) + abs(testPixels.get(i).snapB-cm.newB) + abs(testPixels.get(i).snapG-cm.newG) + abs(testPixels.get(i).snapA-cm.newA);
                
            // Save the RGB in case we end up printing it
            testPixels.get(i).setWorkingDeltaRGB(deltaRGB);            
        }
        // do average
        deltaRGB = deltaRGB/testPixels.size();
        
        return deltaRGB;
    }
    
    public String getFinalSolution()
    {
        String s = String.format("%n");
        s = s + "BEST GUESS: " + bestRGBValues.getColorInfo();
        return s;
    }
    
    class ColorInfo
    {
        float r; // 0-255
        float g; // 0-255
        float b; // 0-255
        float a; // 0-255
        color col;
        int saturation; //-100 to 100
        int brightness; //-100 to 100
        int contrast; // 0-100
        int tintAmount; //-100 to 100
        float deltaRGB;
        
        public ColorInfo(float R, float G, float B, float A, int TintAmount, int Saturation, int Brightness, int Contrast)
        {
            r = R;
            g = G;
            b = B;
            a = A;
            tintAmount = TintAmount;
            saturation = Saturation;
            brightness = Brightness;
            contrast = Contrast;
            col = 0;
            deltaRGB = -1;
        }
        
        public String getColorInfo()
        {
            String str = "";
            // HSV values - convert from color
            col = color(r, g, b, a);
            colorMode(HSB, 360, 100, 100);
            float h = hue(col);
            float s = saturation(col);
            float v = brightness(col);
            colorMode(RGB, 255, 255, 255);
            if (configInfo.readDebugFlag())
            {
                str = "[step size=" + df.format(guessFactor) + ", loop=" + loopCount + "] ";
            }
            str = str + "Avg delta RGB = " + df.format(deltaRGB) + " for RGBA = " + int(r) + ":" + int(g) + ":" + int(b) + ":" + int(a) + " (0x" + hex(col, 6) + ")";            
            str = str + " (HSV = " + int(h) + ":" + int(s) + ":" + int(v) + ")   ";
            str = str + String.format("%n");
            str = str + "Tint amount = " + tintAmount + " saturation = " + saturation + " brightness = " + brightness + " contrast = " + contrast;
            str = str + String.format("%n");
            str = str + "Delta RGB for ";
            for (int i=0; i <testPixels.size(); i++)
            {
                str = str + "(" +  testPixels.get(i).readX() + "," + testPixels.get(i).readY() + ")=" + int(testPixels.get(i).readWorkingDeltaRGB()) + "   ";           
            }
            return str;
        }
    }
}