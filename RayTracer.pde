///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////

int u=0,v=0;   
float lensRadius, focalDistance;
boolean setLens = false;
boolean test1 = true; 
float lightValue = 0;
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
int raysPerPixel;

//Primitive object types
final int base = 0;
final int triangle = 1;
final int sphere = 2;
final int bbox = 3;
final int instance = 4;
final int listType = 5;
final int bvhType = 6;

int timer;

boolean readListFlag = false;


float smallestDist = 1000; 
int closestIndex = -1; 
PVector closestNormal = new PVector(0,0,0);
PVector closestHit;

MatrixStack matrixStack;
PMatrix3D matrix;
List list = new List();   
//Temp list used for creating list object
ArrayList<RenderObj> tempList = new ArrayList<RenderObj>();
/////////////////////////////////////////////////////////////////////
// Some initializations for the scene.
void setup()
{
    size (300, 300, P3D);
    // use P3D environment so that matrix commands work properly
    noStroke();
    colorMode (RGB, 1.0);
    background (0, 0, 0);
    raysPerPixel = 1;
    // grab the global matrix values (to use later when drawing pixels)
    PMatrix3D global_mat = (PMatrix3D) getMatrix();
    global_mat.get(gmat);
//    printMatrix();
    
    //Initializing the matrices and reseting it
    matrixStack = new MatrixStack();
    matrix = new PMatrix3D();
    matrix.reset();
    //resetMatrix();
    // you may want to reset the matrix here
    interpreter("rect_test.cli");
    
}
// Press key 1 to 9 and 0 to run different test cases.
void keyPressed()
{
    test1 = true;
    setLens = false;
    raysPerPixel = 1;
    matrix.reset();
    namedRenderObjs.clear();
    renderObjNames.clear();
    tempList.clear();
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
        case '6':  interpreter("t06.cli");
        break;
        case '7':  interpreter("t07.cli");
        break;
        case '8':  interpreter("t08.cli");
        break;
        case '9':  interpreter("t09.cli");
        break;
        case '0':  interpreter("test.cli");
        break;
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
    RenderObj current = new RenderObj();
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
//          println("Camera: "+camTop+" "+camBottom+" "+camLeft+" "+camRight);
        }
        else if (token[0].equals("background"))
        {
            backgroundColor = new PVector(float(token[1]), float(token[2]), float(token[3]));
        }
        else if (token[0].equals("point_light"))
        {
            PVector lightPosition = new PVector(float(token[1]), float(token[2]), float(token[3]));
            PVector lightColor = new PVector(float(token[4]), float(token[5]), float(token[6]));
            Light point_light = new Light(lightPosition, lightColor, 1, 0.0);
            lights.add(point_light);
        }
        else if( token[0].equals("disk_light") ) {
            PVector center = new PVector(float(token[1]), float(token[2]), float(token[3]));
            float radius = float( token[4] ); 
            PVector normal = new PVector(float(token[5]), float(token[6]), float(token[7]));
            PVector diskColor = new PVector(float(token[8]), float(token[9]), float(token[10]));
           
              
            DiskLight diskLight = new DiskLight(normal, radius, center, diskColor, 2);
              
            lights.add(diskLight);
        }
        else if (token[0].equals("diffuse"))
        {
            PVector diffuseCoeff = new PVector(float(token[1]), float(token[2]), float(token[3]));
            PVector ambientCoeff = new PVector(float(token[4]), float(token[5]), float(token[6]));
            currentSurface = new Material(diffuseCoeff, ambientCoeff);
        }
        
        // Adds the most recent object as a named object 
        else if( token[0].equals("named_object") ) {
          String name = token[1];
          addNamedObject(current, name);
        }

        //Instance reading
        else if( token[0].equals("instance") ) {
         int index = getInstanceIndex(token[1]);
         Instance instance = new Instance(index, matrix);
         renderList.add((Instance) instance);
        }
        
        //Start reading a list of objects
        else if( token[0].equals("begin_list") ) {
          readListFlag = true;  
        } 
        
        //End reading the list of objects and add the list to render list
        else if( token[0].equals("end_list") ) {
          readListFlag = false;
          list = new List();
          int n = tempList.size();
          for( int j = 0; j < n; j++) {
             list.addToList(tempList.get(j));
          }
          ((List)list).calcBoundingBox();
          renderList.add(list);
          tempList.clear();
        }
        
        else if( token[0].equals("end_accel") ) {
          readListFlag = false;
          int accelListSize = tempList.size();
          //Used array instead of arraylist in BVH because I assumed it would be faster. No changes
          RenderObj[] objects = new RenderObj[accelListSize];
          for(int j = 0; j < accelListSize; j++) {
              objects[j] = (Triangle)(tempList.get(j));
              ((Triangle)objects[j]).calcBoundingBox();
          }   
          //The 0 is the x-axis. 1 is y-axis and 2 is z-axis
          BVH bvHierarchy = new BVH(objects, 0);
            
          // Save the list
          renderList.add((BVH) bvHierarchy);
          tempList.clear();

          
        }
        
        else if (token[0].equals("sphere"))
        {
            float radius = float(token[1]);
            PVector center = new PVector(float(token[2]), float(token[3]), float(token[4]));
            
            float[] result = new float[3];
            float[] m = new float[3];
            m[0] = center.x; 
            m[1] = center.y; 
            m[2] = center.z;
            matrix.mult(m,result);
            
            center.x = result[0];
            center.y = result[1];
            center.z = result[2];
            
            Material sphereSurface = new Material(currentSurface);
            Sphere sph = new Sphere(radius, center, sphereSurface);
            sph.primitiveType = sphere;
            current  = (Sphere) sph;
          
        }
        else if (token[0].equals("moving_sphere"))
        {
            float radius = float(token[1]);
            PVector center1 = new PVector(float(token[2]), float(token[3]), float(token[4]));
            PVector center2 = new PVector(float(token[5]), float(token[6]), float(token[7]));
            
            float[] result = new float[3];
            float[] m = new float[3];
            m[0] = center1.x; 
            m[1] = center1.y; 
            m[2] = center1.z;
            matrix.mult(m,result);
            
            center1.x = result[0];
            center1.y = result[1];
            center1.z = result[2];
            
            result = new float[3];
            m = new float[3];
            m[0] = center2.x; 
            m[1] = center2.y; 
            m[2] = center2.z;
            matrix.mult(m,result);
            
            center2.x = result[0];
            center2.y = result[1];
            center2.z = result[2];
            
            Material sphereSurface = new Material(currentSurface);
            MovingSphere movingSphere = new MovingSphere(radius, center1, center2, sphereSurface);
            current = movingSphere;
            renderList.add(movingSphere);
            
        }
        else if( token[0].equals("lens") ) {
          lensRadius = float(token[1]);
          focalDistance = float( token[2] );
          setLens = true;
        }
        else if (token[0].equals("read"))
        {
            // reads input from another file
            interpreter (token[1]);
        }
        else if (token[0].equals("begin")){
            //do nothing
        }
        else if (token[0].equals("vertex")){
            float[] result = new float[3];
            float[] v = new float[3];
            v[0] = float(token[1]); 
            v[1] = float(token[2]); 
            v[2] = float(token[3]);
            matrix.mult(v,result);        

            vertices.add(new PVector(result[0], result[1], result[2]));
            if(vertices.size() == 3)
              {
                  Material triangleShader = new Material(currentSurface);
                  Triangle triangle = new Triangle(vertices.get(0), vertices.get(1), vertices.get(2), triangleShader);
                  triangle.primitiveType=1;
                  //If list is declared then add the triangles to the tempList object.
                  if(!readListFlag){
                      renderList.add((RenderObj)triangle);
                  }
                  else {
                     tempList.add(triangle);
                  }
                  vertices.clear();
              }
        }
        else if (token[0].equals("end")){
 
        }
        else if (token[0].equals("push")){
          matrixStack.push(matrix);
        }
        else if (token[0].equals("pop")){
          PMatrix3D mat = new PMatrix3D();
          mat = matrixStack.pop();
          matrix.set(mat);
        }
        else if (token[0].equals("translate")){
          matrix.translate(float(token[1]), float(token[2]), float(token[3]));
        }
        else if (token[0].equals("rotate")){
          matrix.rotate(radians(float(token[1])),float(token[2]), float(token[3]), float(token[4]));
        }
        else if (token[0].equals("scale")){
          matrix.scale(float(token[1]), float(token[2]), float(token[3]));
        }
        else if (token[0].equals("rays_per_pixel")){
          raysPerPixel = int(token[1]);
          println("Rays per pixel : "+raysPerPixel);
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
        
        else if ( token[0].equals("box")) {
            float xmin, xmax, ymin,ymax,zmin,zmax;
            xmin = Float.parseFloat( token[1] );
            ymin = Float.parseFloat( token[2] );
            zmin = Float.parseFloat( token[3] );
            xmax = Float.parseFloat( token[4] );
            ymax = Float.parseFloat( token[5] );
            zmax = Float.parseFloat( token[6] );      
            
            Box box = new Box();
            Material boxSurface = new Material(currentSurface);
            box.set( xmin, ymin, zmin, xmax, ymax, zmax, boxSurface );
                       
            renderList.add(box);
    
        }
    
        else if (token[0].equals("reset_timer")) {
          timer = millis();
        }
        else if (token[0].equals("print_timer")) {
          int new_timer = millis();
          int diff = new_timer - timer;
          float seconds = diff / 1000.0;
          println ("timer = " + seconds);
        }

        else if (token[0].equals("write"))
        {
          ////////////////////////////////////////
          ///////Start the ray shooting here//////
          ////////////////////////////////////////
          
          Ray currentRay = new Ray();
           for(u = 0; u < height; u++){
             for(v = 0; v < width; v++){
               int correctU = 299 - u;
               colorArray[correctU][v] = new PVector(0,0,0);
               if(raysPerPixel == 1){
                 //get ray to the center of the pixel
                 currentRay = getRayAtPixel(u,v, true);
                 colorArray[correctU][v] = computeColor(renderList, currentRay);
               } 
               else{
                 PVector tempColor = new PVector(0,0,0);
                 //Generating the required number of random rays
                 for(int j = 0; j < raysPerPixel; j++){
                   Ray tempR = getRayAtPixel(u,v, false); 
                   tempColor = computeColor(renderList, tempR);
                   
                   colorArray[correctU][v].x = colorArray[correctU][v].x + tempColor.x;
                   colorArray[correctU][v].y = colorArray[correctU][v].y + tempColor.y;
                   colorArray[correctU][v].z = colorArray[correctU][v].z + tempColor.z;

               }
                 colorArray[correctU][v].x = (float) colorArray[correctU][v].x / (float) raysPerPixel;  
                 colorArray[correctU][v].y = (float) colorArray[correctU][v].y / (float) raysPerPixel;
                 colorArray[correctU][v].z = (float) colorArray[correctU][v].z / (float) raysPerPixel;
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