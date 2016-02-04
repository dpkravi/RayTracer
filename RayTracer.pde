///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////
int screen_width = 300;
int screen_height = 300;
// global matrix values
PMatrix3D global_mat;
float[] gmat = new float[16];
// global matrix values

//////////////////////My CODE////////////////////////////////
ArrayList<RenderObj> renderList = new ArrayList<RenderObj>();
ArrayList<PVector> vertexList = new ArrayList<PVector>();
ArrayList<Light> lights = new ArrayList<Light>();
PVector[][] colorArray = new PVector[300][300];
Material currentSurface;
PVector backgroundColor = new PVector(0,0,0);
//Camera Variables
int fovInDegrees;
float fovInRadians;
float camTop;
float camBottom;
float camLeft;
float camRight;

/////////////////////////////////////////////////////////////////////
// Some initializations for the scene.
void setup()
{
    size (300, 300, P3D);
    // use P3D environment so that matrix commands work properly
    noStroke();
    colorMode (RGB, 1.0);
    background (0, 0, 0);
    // grab the global matrix values (to use later when drawing pixels)
    PMatrix3D global_mat = (PMatrix3D) getMatrix();
    global_mat.get(gmat);
    printMatrix();
    //resetMatrix();
    // you may want to reset the matrix here
    interpreter("rect_test.cli");
}
// Press key 1 to 9 and 0 to run different test cases.
void keyPressed()
{
    switch(key)
    {
        case '1':  interpreter("t01.cli");
        break;
        case '2':  interpreter("t02.cli");
        break;
        case '3':  interpreter("t03.cli");
        break;
        //case '4':  interpreter("t04.cli");
        //break;
        //case '5':  interpreter("t05.cli");
        //break;
        //case '6':  interpreter("t06.cli");
        //break;
        //case '7':  interpreter("t07.cli");
        //break;
        //case '8':  interpreter("t08.cli");
        //break;
        //case '9':  interpreter("t09.cli");
        //break;
        //case '0':  interpreter("t10.cli");
        //break;
        case 'q':  exit();
        break;
    }
}
//  Parser core. It parses the CLI file and processes it based on each
//  token. Only "color", "rect", and "write" tokens are implemented.
//  You should start from here and add more functionalities for your
//  ray tracer.
//
//  Note: Function "splitToken()" is only available in processing 1.25 or higher.
void interpreter(String filename)
{
    String str[] = loadStrings(filename);
    if (str == null) 
        println("Error! Failed to read the file.");
    for (int i=0;i<str.length; i++)
    {
        String[] token = splitTokens(str[i], " ");
        // Get a line and parse tokens.
        if (token.length == 0) continue;
        // Skip blank line.
        if (token[0].equals("fov"))
        {
            fovInDegrees = int(token[1]);
            fovInRadians = ((fovInDegrees * PI)/180.0);
            camTop = (tan(fovInRadians/2));
            camBottom = -(tan(fovInRadians/2));
            camLeft = -(tan(fovInRadians/2));
            camRight = (tan(fovInRadians/2));
            println("Camera: "+camTop+" "+camBottom+" "+camLeft+" "+camRight);
        }
        else if (token[0].equals("background"))
        {
            backgroundColor = new PVector(float(token[1]), float(token[2]), float(token[3]));
        }
        else if (token[0].equals("point_light"))
        {
            PVector lightPosition = new PVector(float(token[1]), float(token[2]), float(token[3]));
            PVector lightColor = new PVector(float(token[4]), float(token[5]), float(token[6]));
            Light point_light = new Light(lightPosition, lightColor);
            lights.add(point_light);
        }
        else if (token[0].equals("diffuse"))
        {
            PVector diffuseCoeff = new PVector(float(token[1]), float(token[2]), float(token[3]));
            PVector ambientCoeff = new PVector(float(token[4]), float(token[5]), float(token[6]));
            currentSurface = new Material(diffuseCoeff, ambientCoeff);
        }
        else if (token[0].equals("sphere"))
        {
            float radius = float(token[1]);
            PVector center = new PVector(float(token[2]), float(token[3]), float(token[4]));
            Material sphereSurface = new Material(currentSurface);
            Sphere sphere = new Sphere(radius, center, sphereSurface);
            renderList.add(sphere);
            
            println(float(token[2]) +" "+ float(token[3]) +" "+ float(token[4]));
        }
        else if (token[0].equals("read"))
        {
            // reads input from another file
            interpreter (token[1]);
        }
        else if (token[0].equals("color"))
        {
            // example command -- not part of ray tracer
            float r = float(token[1]);
            float g = float(token[2]);
            float b = float(token[3]);
            fill(r, g, b);
        }
        else if (token[0].equals("rect"))
        {
            // example command -- not part of ray tracer
            float x0 = float(token[1]);
            float y0 = float(token[2]);
            float x1 = float(token[3]);
            float y1 = float(token[4]);
            rect(x0, screen_height-y1, x1-x0, y1-y0);
        }
        else if (token[0].equals("write"))
        {
          ////////////////////////////////////////
          ///////Start the ray shooting here//////
          ////////////////////////////////////////
           for(int u = 0; u < height; u++){
             for(int v = 0; v < width; v++){
               int correctU = 299 - u;
               colorArray[correctU][v] = new PVector(-1,-1,-1);
               PVector origin = new PVector(0,0,0);
               PVector target = new PVector(camLeft + ((camRight-camLeft)*(v+.5)/width), camBottom+ ((camTop-camBottom)*(u+.5)/height), -1.0);
               PVector direction = new PVector(target.x - origin.x, target.y - origin.y, -1.0); 
               //Normalizing the direction
               direction.normalize();
               //Create a ray from eye to this pixel direction
               Ray currentRay = new Ray(origin, direction);
               //Loops through all the renderable objects
               if(renderList.size() > 0)
               {  
                 int closestObj = firstIntersection(renderList, currentRay);
                 //No intersection happened
                 if(closestObj == -1 )
                 {
                     colorArray[correctU][v] = backgroundColor;
                 }
                 else
                 {
                      RenderObj currentRenderObj = renderList.get(closestObj);
                      RayCollInfo rayCollInfo = currentRenderObj.intersection(currentRay);
                      if(rayCollInfo.isHit)
                      {
                          colorArray[correctU][v] = getColor(lights, currentRenderObj, rayCollInfo);
                      }
                      else
                      {
                           colorArray[correctU][v] = backgroundColor;
                      }
                  }
               }
               
             } 
           } 
            loadPixels();
            if(!filename.equals("rect_test.cli"))
            {
                // Convert the color array for updating Pixels to screen
                for(int u = 0;u < height; u++){
                    for (int v = 0; v < width; v++){
                        if(colorArray[u][v].x>=0)
                          pixels[u*300+v] = color(colorArray[u][v].x,colorArray[u][v].y,colorArray[u][v].z);
                        else
                          pixels[u*300+v] = color(backgroundColor.x,backgroundColor.y,backgroundColor.z);
                    }
                }
            }
            updatePixels();
            save(token[1]);
            renderList.clear();
            lights.clear();
            //Reset background to black after each render
            backgroundColor = new PVector(0,0,0);
        }
    }
}
//  Draw frames.  Should be left empty.
void draw()
{
}
// when mouse is pressed, print the cursor location
void mousePressed()
{
    println ("mouse: " + mouseX + " " + mouseY);
}