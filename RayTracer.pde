///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////

int timer = 0;
float fov = 0;

int screen_width = 600;
int screen_height = 600;

// global matrix values
PMatrix3D global_mat;
float[] gmat = new float[16];
// global matrix values

PVector backgroundColor = new PVector(0,0,0);
private ArrayList<Light> lights =  new ArrayList<Light>();;     
private ArrayList<RenderObj> renderList  = new ArrayList<RenderObj>();
ArrayList<PVector> vertices = new ArrayList<PVector>();

MatrixStack matrixStack;
PMatrix3D matrix;

kd_tree photons;

// variables for the photon mapping
boolean diffuse = false;
boolean caustic = false;
int num_cast = 0;
int num_near = 0;
float max_near_dist = 0;

// Some initializations for the scene.
Material currentMaterial;

void setup(){
  size (600, 600, P3D); 
  noStroke();
  colorMode (RGB, 1.0);
  background (0, 0, 0);
     
  //Initializing the matrices and reseting it
  matrixStack = new MatrixStack();
  matrix = new PMatrix3D();
  matrix.reset();
  //resetMatrix();
  interpreter("t01.cli");
 
}

// Press key 1 to 9 and 0 to run different test cases.

void keyPressed() {
  matrix.reset();
  lights.clear();
  renderList.clear();
  caustic = false;
  diffuse = false;
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

void interpreter(String filename) {
  
  String str[] = loadStrings(filename);
  if (str == null){
    println("Error! Failed to read the file.");
  }
  else{
    for (int i=0; i<str.length; i++) {
      
      String[] token = splitTokens(str[i], " "); 
      
      if (token.length == 0) continue; 
      
      else if (token[0].equals("fov")) {
          fov = Float.parseFloat(token[1]);
      }
      else if (token[0].equals("background")) {
          backgroundColor = new PVector(Float.parseFloat(token[1]), Float.parseFloat(token[2]), Float.parseFloat(token[3]));
      }
      else if (token[0].equals("point_light")) {
            PVector lightPosition = new PVector(float(token[1]), float(token[2]), float(token[3]));
            PVector lightColor = new PVector(float(token[4]), float(token[5]), float(token[6]));
            Light point_light = new Light(lightPosition, lightColor);
            lights.add(point_light);
      }
      else if (token[0].equals("diffuse")) {
        PVector diffuseCoeff = new PVector(Float.parseFloat(token[1]), Float.parseFloat(token[2]), Float.parseFloat(token[3]));
        PVector ambientCoeff = new PVector(Float.parseFloat(token[4]), Float.parseFloat(token[5]), Float.parseFloat(token[6]));
        currentMaterial = new Material(diffuseCoeff, ambientCoeff);
      }
      else if(token[0].equals("reflective")){
        PVector diffuseCoeff = new PVector(Float.parseFloat(token[1]), Float.parseFloat(token[2]), Float.parseFloat(token[3]));
        PVector ambientCoeff = new PVector(Float.parseFloat(token[4]), Float.parseFloat(token[5]), Float.parseFloat(token[6]));
        float reflectCoeff = Float.parseFloat(token[7]);
        currentMaterial = new Material(diffuseCoeff, ambientCoeff, reflectCoeff);
      }
      else if (token[0].equals("sphere")) {
        PVector center = new PVector(Float.parseFloat(token[2]), Float.parseFloat(token[3]), Float.parseFloat(token[4]));
        float radius = Float.parseFloat(token[1]);
     
        float[] result = new float[3];
        float[] m = new float[3];
        m[0] = center.x; 
        m[1] = center.y; 
        m[2] = center.z;
        matrix.mult(m,result);
        
        center.x = result[0];
        center.y = result[1];
        center.z = result[2];
        
        Sphere newShape = new Sphere(radius, center, currentMaterial);
            
        renderList.add(newShape);
      }
      
      else if(token[0].equals("hollow_cylinder")){
        
        float radius = Float.parseFloat(token[1]);
        PVector position = new PVector(Float.parseFloat(token[2]), Float.parseFloat(token[4]), Float.parseFloat(token[3]));
        float ymax = Float.parseFloat(token[5]);
        Hollow_Cylinder newShape = new Hollow_Cylinder(radius, position, ymax, currentMaterial);
        renderList.add(newShape);
      }
      
      else if(token[0].equals("push")){
          matrixStack.push(matrix);
      }
      else if(token[0].equals("pop")){
          PMatrix3D mat = new PMatrix3D();
          mat = matrixStack.pop();
          matrix.set(mat);
      }
      else if(token[0].equals("translate")){
          matrix.translate(float(token[1]), float(token[2]), float(token[3]));
      }
      else if(token[0].equals("scale")){
          matrix.scale(float(token[1]), float(token[2]), float(token[3]));
      }
      else if(token[0].equals("rotate")){
          matrix.rotate(radians(float(token[1])),float(token[2]), float(token[3]), float(token[4]));
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
                Triangle triangle = new Triangle(vertices.get(0), vertices.get(1), vertices.get(2), currentMaterial);
                renderList.add((RenderObj)triangle);
                vertices.clear();
            }
      }
      else if (token[0].equals("end")){
           //do nothing
      }
      else if(token[0].equals("caustic_photons")){
        caustic = true;
        diffuse = false; 
        num_cast = Integer.parseInt(token[1]);
        num_near = Integer.parseInt(token[2]);
        max_near_dist = Float.parseFloat(token[3]);

      }
      else if(token[0].equals("diffuse_photons")){
        //Not implemented :(
        caustic = false;
        diffuse = true; 
        num_cast = Integer.parseInt(token[1]);
        num_near = Integer.parseInt(token[2]);
        max_near_dist = Float.parseFloat(token[3]);
      }
      
      else if (token[0].equals("read")) {  // reads input from another file
        interpreter (token[1]);
      }
      else if (token[0].equals("color")) {  // example command -- not part of ray tracer
       float r = float(token[1]);
       float g = float(token[2]);
       float b = float(token[3]);
       fill(r, g, b);
      }
      else if (token[0].equals("rect")) {  // example command -- not part of ray tracer
       float x0 = float(token[1]);
       float y0 = float(token[2]);
       float x1 = float(token[3]);
       float y1 = float(token[4]);
       rect(x0, screen_height-y1, x1-x0, y1-y0);
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
      else if (token[0].equals("write")) {
        
        //In the caustic files, the tree has to be built before calling the raytrace function
        if(caustic){
            //initialize new kd-tree
           photons = new kd_tree();
           
           float randomX, randomY, randomZ;
           PVector lightPos = lights.get(0).position;
           PVector lightColour = lights.get(0).colour;
           Ray ray = new Ray(lightPos, new PVector());
           for(int j=0; j < num_cast; j++){
               //Subtracting 1 to normalize the point
               randomX = random(2)-1.0;
               randomY = random(2)-1.0;
               randomZ = random(2)-1.0;
               // Rejection sampling to pick a point in the sphere.
               while((sq(randomX) + sq(randomY) + sq(randomZ)) > 1){
                 randomX = random(2)-1.0;
                 randomY = random(2)-1.0;
                 randomZ = random(2)-1.0;
               }
               ray.direction = new PVector(randomX, randomY, randomZ);
               PVector photonColor = new PVector(lightColour.x, lightColour.y, lightColour.z);
               //Multiplying the power of the photons by 8 to increase the brightness
               photonColor = photonColor.mult(8);
               emitPhoton(ray, false, photonColor);
           }
           photons.build_tree();
           println("Caustic kd-tree constructed");
        }
        getColor();
        //Write image to file
        save(token[1]);  
      }
    }
  }
}

void draw() {

}

// when mouse is pressed, print the cursor location
void mousePressed() {
  println ("mouse: " + mouseX + " " + mouseY);
}