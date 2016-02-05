///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////
import java.util.Stack;

boolean test1 = true;
    
boolean isPush = false;
// boolean isPop = false;
    
int screen_width = 300;
int screen_height = 300;
// global matrix values
PMatrix3D global_mat;
float[] gmat = new float[16];
// global matrix values

//////////////////////My CODE////////////////////////////////
ArrayList<RenderObj> renderList = new ArrayList<RenderObj>();
ArrayList<PVector> vertices = new ArrayList<PVector>();
ArrayList<Light> lights = new ArrayList<Light>();
PVector[][] colorArray = new PVector[300][300];

ArrayList<float[][]> transformList = new ArrayList<float[][]>();
//Stack<ArrayList<float[][]>> stackList = new Stack<ArrayList<float[][]>>();

ArrayList<RenderStack> transformStackList = new ArrayList<RenderStack>();

Material currentSurface;
PVector backgroundColor = new PVector(0,0,0);
//Camera Variables
int fovInDegrees;
float fovInRadians;
float camTop;
float camBottom;
float camLeft;
float camRight;
boolean shadows;
int currentLevel = 0;;

float[][] vertMat = new float[4][1];

float[][] transformMat = new float[4][4];
float[][] currentMatrix = new float[4][4];
//Stack<float[][]> matrixStack = new Stack<float[][]>();

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
    test1 = true;
    transformList.clear();
    transformStackList.clear();
    
    switch(key)
    {
        case '1':  interpreter("t01.cli");
        break;
        case '2':  interpreter("t02.cli");
        break;
        case '3':  interpreter("t03.cli");
        break;
        case '4':  interpreter("t04.cli");
        break;
        case '5':  interpreter("t05.cli");
        break;
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
        else if (token[0].equals("begin")){
          //Ignore
        }
        else if (token[0].equals("vertex")){
            PVector vertex = new PVector(float(token[1]), float(token[2]), float(token[3]));
            if(isPush){
               float[][] transformedMat = new float[4][1];
               vertMat[0][0] =  float(token[1]);
               vertMat[1][0] =  float(token[2]);
               vertMat[2][0] =  float(token[3]);
               vertMat[3][0] =  1.0;
               for(int a = 0; a < transformStackList.size(); a++){
                 if(transformStackList.get(a).level<=currentLevel){
                   vertMat = matrixMult(transformStackList.get(a).tranMat, vertMat);
                   println("Transformed Matrix");
                   printMat(vertMat);
                 }
               }
               vertex.x = vertMat[0][0]/vertMat[3][0];
               vertex.y = vertMat[1][0]/vertMat[3][0];
               vertex.z = vertMat[2][0]/vertMat[3][0];
               vertices.add(vertex);
            }
            else{
              vertices.add(vertex);
            }
            if(vertices.size() == 3)
              {
                  Material triangleShader = new Material(currentSurface);
                  Triangle triangle = new Triangle(vertices.get(0), vertices.get(1), vertices.get(2), triangleShader);
                  renderList.add((RenderObj)triangle);
                  println("Vertices of the Triangle");
                  println(vertices.get(0));
                  println(vertices.get(1));
                  println(vertices.get(2));
                  vertices.clear();
              }
        }
        else if (token[0].equals("end")){
          //Ignore
        }
        else if (token[0].equals("push")){
          isPush = true;
          currentLevel++;
        }
        else if (token[0].equals("pop")){
          isPush = false;
          currentLevel--;
        //   transformList.pop();
        }
        else if (token[0].equals("translate")){
          transformStackList.add(new RenderStack(createTranslateMat(float(token[1]), float(token[2]), float(token[3])), currentLevel));
        }
        else if (token[0].equals("rotate")){
          transformStackList.add(new RenderStack(createRotateMat(float(token[1]), float(token[2]), float(token[3]), float(token[4])), currentLevel));
        }
        else if (token[0].equals("scale")){
          transformStackList.add(new RenderStack(createScaleMat(float(token[1]), float(token[2]), float(token[3])), currentLevel));
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
          println("renderlist size"+ renderList.size());
          ////////////////////////////////////////
          ///////Start the ray shooting here//////
          ////////////////////////////////////////
          boolean test = true;
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
                 if(closestObj != -1 && test){
                   println("test");
                   test= false;
                 }
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
                          colorArray[correctU][v] = getColor(lights,renderList,currentRenderObj, rayCollInfo);
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