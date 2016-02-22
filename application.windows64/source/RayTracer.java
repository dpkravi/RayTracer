import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class RayTracer extends PApplet {

///////////////////////////////////////////////////////////////////////
//
//  Ray Tracing Shell
//
///////////////////////////////////////////////////////////////////////

int testCounter = 0;

float mMinDist = 1000; 
int mMinInd = -1; 
PVector mMinNormal = new PVector(0,0,0);

int u=0,v=0;   

float lensRadius, focalDistance;
boolean setLens = false;
boolean test1 = true; 
float lparam = 0;
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


 MatrixStack matrixStack;
 PMatrix3D matrix;
    
/////////////////////////////////////////////////////////////////////
// Some initializations for the scene.
public void setup()
{
    
    // use P3D environment so that matrix commands work properly
    noStroke();
    colorMode (RGB, 1.0f);
    background (0, 0, 0);
    raysPerPixel = 1;
    // grab the global matrix values (to use later when drawing pixels)
    PMatrix3D global_mat = (PMatrix3D) getMatrix();
    global_mat.get(gmat);
    printMatrix();
    
    //Initializing the matrices and reseting it
    matrixStack = new MatrixStack();
    matrix = new PMatrix3D();
    matrix.reset();
    //resetMatrix();
    // you may want to reset the matrix here
    interpreter("rect_test.cli");
}
// Press key 1 to 9 and 0 to run different test cases.
public void keyPressed()
{
    test1 = true;
    setLens = false;
    raysPerPixel = 1;
    matrix.reset();
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
public void interpreter(String filename)
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
            fovInDegrees = PApplet.parseInt(token[1]);
            fovInRadians = ((fovInDegrees * PI)/180.0f);
            camTop = (tan(fovInRadians/2));
            camBottom = -(tan(fovInRadians/2));
            camLeft = -(tan(fovInRadians/2));
            camRight = (tan(fovInRadians/2));
            println("Camera: "+camTop+" "+camBottom+" "+camLeft+" "+camRight);
        }
        else if (token[0].equals("background"))
        {
            backgroundColor = new PVector(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
        }
        else if (token[0].equals("point_light"))
        {
            PVector lightPosition = new PVector(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
            PVector lightColor = new PVector(PApplet.parseFloat(token[4]), PApplet.parseFloat(token[5]), PApplet.parseFloat(token[6]));
            Light point_light = new Light(lightPosition, lightColor, 1, 0.0f);
            lights.add(point_light);
        }
        else if( token[0].equals("disk_light") ) {
            PVector center = new PVector(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
            float radius = PApplet.parseFloat( token[4] ); 
            PVector normal = new PVector(PApplet.parseFloat(token[5]), PApplet.parseFloat(token[6]), PApplet.parseFloat(token[7]));
            PVector diskColor = new PVector(PApplet.parseFloat(token[8]), PApplet.parseFloat(token[9]), PApplet.parseFloat(token[10]));
           
              
            DiskLight diskLight = new DiskLight(normal, radius, center, diskColor, 2);
              
            lights.add(diskLight);
        }
        else if (token[0].equals("diffuse"))
        {
            PVector diffuseCoeff = new PVector(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
            PVector ambientCoeff = new PVector(PApplet.parseFloat(token[4]), PApplet.parseFloat(token[5]), PApplet.parseFloat(token[6]));
            currentSurface = new Material(diffuseCoeff, ambientCoeff);
        }
        else if (token[0].equals("sphere"))
        {
            float radius = PApplet.parseFloat(token[1]);
            PVector center = new PVector(PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]), PApplet.parseFloat(token[4]));
            
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
            Sphere sphere = new Sphere(radius, center, sphereSurface);
            renderList.add(sphere);
            
            //println(float(token[2]) +" "+ float(token[3]) +" "+ float(token[4]));
        }
        else if (token[0].equals("moving_sphere"))
        {
            float radius = PApplet.parseFloat(token[1]);
            PVector center1 = new PVector(PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]), PApplet.parseFloat(token[4]));
            PVector center2 = new PVector(PApplet.parseFloat(token[5]), PApplet.parseFloat(token[6]), PApplet.parseFloat(token[7]));
            
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
            renderList.add(movingSphere);
            
            //println(float(token[2]) +" "+ float(token[3]) +" "+ float(token[4]));
        }
        else if( token[0].equals("lens") ) {
          lensRadius = PApplet.parseFloat(token[1]);
          focalDistance = PApplet.parseFloat( token[2] );
          setLens = true;
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
            float[] result = new float[3];
            float[] v = new float[3];
            v[0] = PApplet.parseFloat(token[1]); 
            v[1] = PApplet.parseFloat(token[2]); 
            v[2] = PApplet.parseFloat(token[3]);
            matrix.mult(v,result);        

            vertices.add(new PVector(result[0], result[1], result[2]));
            if(vertices.size() == 3)
              {
                  Material triangleShader = new Material(currentSurface);
                  Triangle triangle = new Triangle(vertices.get(0), vertices.get(1), vertices.get(2), triangleShader);
                  renderList.add((RenderObj)triangle);
                  //println("Vertices of the Triangle");
                  //println(vertices.get(0));
                  //println(vertices.get(1));
                  //println(vertices.get(2));
                  vertices.clear();
              }
        }
        else if (token[0].equals("end")){
          //Ignore
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
          matrix.translate(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
        }
        else if (token[0].equals("rotate")){
          matrix.rotate(radians(PApplet.parseFloat(token[1])),PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]), PApplet.parseFloat(token[4]));
        }
        else if (token[0].equals("scale")){
          matrix.scale(PApplet.parseFloat(token[1]), PApplet.parseFloat(token[2]), PApplet.parseFloat(token[3]));
        }
        else if (token[0].equals("rays_per_pixel")){
          raysPerPixel = PApplet.parseInt(token[1]);
          println("Rays per pixel : "+raysPerPixel);
        }
        else if (token[0].equals("color"))
        {
            // example command -- not part of ray tracer
            float r = PApplet.parseFloat(token[1]);
            float g = PApplet.parseFloat(token[2]);
            float b = PApplet.parseFloat(token[3]);
            fill(r, g, b);
        }
        else if (token[0].equals("rect"))
        {
            // example command -- not part of ray tracer
            float x0 = PApplet.parseFloat(token[1]);
            float y0 = PApplet.parseFloat(token[2]);
            float x1 = PApplet.parseFloat(token[3]);
            float y1 = PApplet.parseFloat(token[4]);
            rect(x0, screen_height-y1, x1-x0, y1-y0);
        }
        else if (token[0].equals("write"))
        {
          println("Renderlist size : "+ renderList.size());
          ////////////////////////////////////////
          ///////Start the ray shooting here//////
          ////////////////////////////////////////
          boolean test = true;
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
               //print( colorArray[correctU][v]);
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
public void draw()
{
}
// when mouse is pressed, print the cursor location
public void mousePressed()
{
    println ("mouse: " + mouseX + " " + mouseY);
}
//This will be the base class from which shapes will be extended
//Currently only spheres are used. 
abstract class RenderObj
{
    Material material;
    RenderObj(Material m)
    {
        material = m;
    }
    public abstract RayCollInfo intersection(Ray r);
}

class Light
{
    PVector position;
    PVector colour;
    float radius;
    int lightType;
    public Light(PVector position,PVector colour, int lightType, float radius)
    {
        this.position = position;
        this.colour = colour;
        this.lightType = lightType;
        this.radius = radius;
    }
}

class DiskLight extends Light
{
    PVector normal;
    float radius;
    DiskLight(PVector normal, float radius,PVector position,PVector colour, int lightType){
      super(position,colour,lightType, radius);
      this.normal = normal;
      this.radius = radius;
    }
}


class Material
{
    PVector diffuseCoeff;
    PVector ambientCoeff;
    public Material(PVector d, PVector a)
    {
        diffuseCoeff = d;
        ambientCoeff = a;
    }
    public Material(Material m)
    {
        diffuseCoeff = m.diffuseCoeff;
        ambientCoeff = m.ambientCoeff;
    }
}

class Ray
{
    PVector origin;
    PVector direction;
    Ray(){
        origin = new PVector(0,0,0);
        direction = new PVector(0,0,0);
    }
    Ray(PVector origin, PVector direction)
    {
        this.origin = origin;
        this.direction = direction;
    }
}

//This class represents the ray intersection data and stores the vectors, normal and isHit or not
class RayCollInfo
{
    PVector reflVec;
    PVector hitVec;
    PVector normal;
    boolean isHit;
    boolean isTriangle;
    float rootVal;
    public RayCollInfo (PVector reflVec, PVector hitVec,PVector normal, boolean isHit, float rootVal)
    {
        this.reflVec = reflVec;
        this.hitVec = hitVec;
        this.normal = normal;
        this.isHit = isHit;
        this.rootVal = rootVal;
    }
    public RayCollInfo(boolean isHit, boolean isTriangle)
    {
        this.isHit = isHit;
    }
    public RayCollInfo(boolean isHit)
    {
        this.isHit = isHit;
    }
}


class Sphere extends RenderObj
{
    PVector center;
    float radius;
    Sphere(float radius, PVector center, Material m)
    {
        super(m);
        this.radius = radius;
        this.center = center;
    }
    
    public RayCollInfo intersection(Ray r)
    {
        //Used some formulae from https://en.wikipedia.org/wiki/Line%E2%80%93sphere_intersection & 
        // http://www.ccs.neu.edu/home/fell/CSU540/programs/RayTracingFormulas.htm for reference
        RayCollInfo rayCollInfo;
        //(o-c)
        PVector sphereVector = new PVector(r.origin.x - center.x, r.origin.y - center.y, r.origin.z - center.z);
        //(l.(o-c))^2
        float BSquare = pow(r.direction.dot(sphereVector), 2);
        // ||l||^2  ->  l.l
        float A = r.direction.dot(r.direction);
        // ||o-c||^2
        float SVecSquare = sphereVector.dot(sphereVector);
        float rSquare = pow(this.radius,2);
        float AC = A * (SVecSquare - rSquare);
        //Discriminant D
        float D = BSquare - AC;
        if(D >= 0)
        {
            //Square root of discriminant
            float RootD = pow(D, .5f);
            // -l.(o-c)
            float minusB = -r.direction.dot(sphereVector);
            // Numerator -B +/- rootD
            float num = min(minusB - RootD, minusB - RootD);
            //root of quadratic equation
            float root = num/A;
            //If ray intersection happens then root will be a positive value
            if(root > 0.0000001f)
            {
                PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z );
                PVector hitPosition = new PVector(r.direction.x, r.direction.y, r.direction.z);
                hitPosition.mult(root);
                hitPosition.add(r.origin);
                // Find the normal vector to the sphere at (x, y, z)
                PVector normal = new PVector((hitPosition.x - center.x)/radius, (hitPosition.y - center.y)/radius, (hitPosition.z - center.z)/radius);
                rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, normal, true, root);
                return rayCollInfo;
            }
            // No intersection happened
            else
            {
                rayCollInfo = new RayCollInfo(false);
                return rayCollInfo;
            }
        }
        // no intersection happened
        else
        {
            rayCollInfo = new RayCollInfo(false);
            return rayCollInfo;
        }
    }
}

class MovingSphere extends RenderObj {

   PVector startPos;   //Start position of movement
   PVector endPos;   //End position of movement
   PVector speed;   //Rate of movement between startPos and endPos 
   PVector center;
   float radius; 
  
  /** Constructor */
  MovingSphere(float radius, PVector center1, PVector center2, Material m) {
    super(m);
    this.radius = radius;
    this.startPos = center1; 
    this.endPos = center2;
    this.speed = new PVector( endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z );
  //  this.center = new PVector( (startPos.x + endPos.x)/2, (startPos.z + endPos.z)/2, (startPos.z + endPos.z)/2);
  }
  
  public RayCollInfo intersection(Ray r)
  {

      RayCollInfo rayCollInfo;

      float dt = (float)( Math.random() );
      center = new PVector(startPos.x + dt*speed.x, startPos.y + dt*speed.y, startPos.z + dt*speed.z);
      PVector sphereVector = new PVector(r.origin.x - center.x, r.origin.y - center.y, r.origin.z - center.z);
      float BSquare = pow(r.direction.dot(sphereVector), 2);
      float A = r.direction.dot(r.direction);
      float SVecSquare = sphereVector.dot(sphereVector);
      float rSquare = pow(this.radius,2);
      float AC = A * (SVecSquare - rSquare);
      float D = BSquare - AC;
      if(D >= 0)
      {
          float RootD = pow(D, .5f);
          float minusB = -r.direction.dot(sphereVector);
          float num = min(minusB - RootD, minusB - RootD);
          float root = num/A;
          if(root > 0.0000001f)
          {
              PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z );
              PVector hitPosition = new PVector(r.direction.x, r.direction.y, r.direction.z);
              hitPosition.mult(root);
              hitPosition.add(r.origin);
              // Find the normal vector to the sphere at (x, y, z)
              PVector normal = new PVector((hitPosition.x - center.x)/radius, (hitPosition.y - center.y)/radius, (hitPosition.z - center.z)/radius);
              rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, normal, true, root);
              return rayCollInfo;
          }
          // No intersection happened
          else
          {
              rayCollInfo = new RayCollInfo(false);
              return rayCollInfo;
          }
      }
      // no intersection happened
      else
      {
          rayCollInfo = new RayCollInfo(false);
          return rayCollInfo;
      }
  }


  
}

class Triangle extends RenderObj
{
    PVector vertex1;
    PVector vertex2;
    PVector vertex3;
    Triangle(PVector v1, PVector v2, PVector v3, Material m)
    {
        super(m);
        vertex1 = v1;
        vertex2 = v2;
        vertex3 = v3;
    }
    public RayCollInfo intersection(Ray r)
    {
      
       float epsilon = 0.0000001f;
       //Two edges of triangle to calculate the normal
       PVector edge1 = createVec(vertex1,vertex3);
       PVector edge2 = createVec(vertex1,vertex2);
       //PVector edge1 = new PVector(vertex3.x - vertex1.x, vertex3.y - vertex1.y, vertex3.z - vertex1.z);
       //PVector edge2 = new PVector(vertex2.x - vertex1.x, vertex2.y - vertex1.y, vertex2.z - vertex1.z);
        
       //Cross product of the two edges gives the surface normal of the triangle
       PVector normal = edge1.cross(edge2);

       normal.normalize();
        
        
       // Invert the normals when they are flipped
       if(normal.dot(r.direction)>0){
          normal.mult(-1);
       }
        
       // Implementing the M\u00f6ller\u2013Trumbore intersection algorithm   -   https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
        
       //If ray direction and surface normal were perpendicular to each other then the ray is parallel to the surface
       if(r.direction.dot(normal) != 0)
       {
           PVector e1 = createVec(vertex2, vertex1);
           PVector e2 = createVec(vertex3, vertex1);
           PVector e3 = createVec(r.origin, vertex1); 
           PVector rayDir = new PVector(r.direction.x, r.direction.y, r.direction.z);
            
           PVector cross1 = new PVector(0.0f,0.0f,0.0f);
           cross1.x = e2.y*rayDir.z - e2.z*rayDir.y;
           cross1.y = e2.z*rayDir.x - e2.x*rayDir.z;
           cross1.z = e2.x*rayDir.y - e2.y*rayDir.x;
            
           float det = e1.x*cross1.x + e1.y*cross1.y + e1.z*cross1.z;
            
           PVector cross2 = new PVector(0.0f,0.0f,0.0f);
           cross2.x = e1.y*e3.z - e1.z*e3.y;
           cross2.y = e1.z*e3.x - e1.x*e3.z;
           cross2.z = e1.x*e3.y - e1.y*e3.x;
            
           float d = e2.x*cross2.x + e2.y*cross2.y + e2.z*cross2.z;
            
           float determinant = -d/det;
            
           //if determinant is near zero, then ray lies in plane of triangle
           if(determinant < epsilon){
             return new RayCollInfo(false, true);
           }
            
           float u = (rayDir.x*cross2.x + rayDir.y*cross2.y + rayDir.z*cross2.z)/det; 
            
           //The intersection lies outside of the triangle
           if(u < 0 || u > 1){
               return new RayCollInfo(false, true);
           }
            
           float v = (e3.x*cross1.x + e3.y*cross1.y + e3.z*cross1.z)/det;
            
           //The intersection lies outside of the triangle
           if(v < 0 || u + v > 1){
               return new RayCollInfo(false, true);
           }
            
           PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z );
           PVector hitPosition = new PVector(r.direction.x, r.direction.y, r.direction.z);
           hitPosition.mult(determinant);
            
           reflectionVector.normalize();
            
           return new RayCollInfo(reflectionVector, hitPosition, normal, true, determinant);
          
       }
       else
           return new RayCollInfo(false, true);
    }
}

public class MatrixStack {
  private int size = 0;
  private PMatrix3D tranMats[];
  private static final int max = 50;

    public MatrixStack() {
        tranMats = new PMatrix3D[max];
        for(int i=0; i<max; ++i) {
          tranMats[i] = new PMatrix3D();
          tranMats[i].reset();
        }
    }
    public void push(PMatrix3D matrix) {
        if(size == tranMats.length) {
          print("Matrix Stack capacity exceeded");
          return;
        }   
        tranMats[size].set(matrix);
        size++;
    }
    public PMatrix3D pop() {
        PMatrix3D matrix = new PMatrix3D(); 
        matrix.set(tranMats[size - 1]);
        tranMats[size-1].reset();
        size--;
        return matrix;
    }
};
public int firstIntersection(ArrayList<RenderObj> renderList, Ray currentRay)
{
    //Create a list of all the ray object intersections for this particular ray
    ArrayList<Integer> collList = new ArrayList<Integer>();

    //if(test1){
    //  println(renderList.size());
    //  test1 = false;
    //}
    for(int i = 0; i < renderList.size(); i++)
    {
        RenderObj newRenderable = renderList.get(i);
        RayCollInfo newRayCollInfo = newRenderable.intersection(currentRay);
        if(newRayCollInfo.isHit)
        {
            collList.add(i);
        }
    }

    if(collList.size() > 0)
    {
        RenderObj closestObject = renderList.get(collList.get(0));
        RayCollInfo rayCollInfo = closestObject.intersection(currentRay);
        int retIndex = collList.get(0);
        //Compare the root values and the lowest value gives the first intersection
        for(int k = 1; k < collList.size(); k++)
        {
            RenderObj newRenderObj =  renderList.get(collList.get(k));
            RayCollInfo newRayCollInfo = newRenderObj.intersection(currentRay);
            if(newRayCollInfo.rootVal < rayCollInfo.rootVal)
            {
                closestObject = newRenderObj;
                rayCollInfo = newRayCollInfo;
                retIndex = collList.get(k);
            }
        }
        return retIndex;
    }
    else
    {
        return -1;
    }
}

public Ray getPointLightShadowRay(Light light, PVector hitVec){
  
    PVector normal = createVec(hitVec, light.position).normalize();
    PVector pos = new PVector(hitVec.x+0.0002f*normal.x,hitVec.y+0.0002f*normal.y,hitVec.z+0.0002f*normal.z);
    Ray R = new Ray(pos, normal);
    return R;
}

public Ray getDiskLightShadowRay(Light light, PVector hitVec){
  
     // Hack to verify that it works. We know that normal is always towards X (I am being lazy here, but the
     // only hack so far is to do the randomization simpler in plane YZ - UPDATE THIS!)
     PVector P = new PVector(0,0,0);
     float dr = sqrt((float)Math.random());
     float dt = 2*3.14157f*(float)Math.random();
     P.x = light.position.x;
     P.y = light.position.y + light.radius*dr*cos(dt);
     P.z = light.position.z + light.radius*dr*sin(dt);     
     
     PVector normal = createVec(hitVec, P).normalize();

     PVector pos = new PVector(hitVec.x+0.0002f*normal.x,hitVec.y+0.0002f*normal.y,hitVec.z+0.0002f*normal.z);
     Ray R = new Ray(pos, normal);
     testCounter++;
     return R;

}


public boolean isInShadow(Ray shadowRay){
    for( int i = 0; i < renderList.size(); i++ ) {
       if( isIntersect(shadowRay, i ) == true ) { return true; }
    }
    return false;
}

public boolean isIntersect( Ray shadowRay, int i ) {
    RayCollInfo shadowIntersection = renderList.get(i).intersection(shadowRay);
    if(shadowIntersection.isHit && shadowIntersection.rootVal <= lparam)
    {
        return true;
    }
    else{
        return false;
    }
 }

public PVector getColor(ArrayList<Light> lights, ArrayList<RenderObj> renderList, RenderObj currentObj, RayCollInfo rayCollInfo)
{
   
    //Ambient color
    PVector finalColor = new PVector(currentObj.material.ambientCoeff.x, currentObj.material.ambientCoeff.y, currentObj.material.ambientCoeff.z);
    for(int i = 0; i < lights.size(); i++)
    {
        Light currentLight = lights.get(i);
        Ray shadowRay = new Ray();
        if(currentLight.lightType == 1){
            shadowRay = getPointLightShadowRay(lights.get(i), rayCollInfo.hitVec);
        }
        if(currentLight.lightType == 2){
            shadowRay = getDiskLightShadowRay(lights.get(i), rayCollInfo.hitVec);
        } 

        PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        lparam = lightVec.mag();
        if(isInShadow(shadowRay) == false){
            lightVec.normalize();
            rayCollInfo.normal.normalize();
            // (N.L)
            float NL = abs(max(rayCollInfo.normal.dot(shadowRay.direction), 0));
            if(NL == 0)
            print(NL+" ");
            PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
            finalColor.x = finalColor.x + diffuseShading.x;
            finalColor.y = finalColor.y + diffuseShading.y;
            finalColor.z = finalColor.z + diffuseShading.z;
            //if(finalColor.x == 0.2 && finalColor.y == 0.2 && finalColor.z == 0.2)
            // println("test");
        
        }

        //shadows = false;
        //Light currentLight = lights.get(i);
        //PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        //for( int j = 0; j< renderList.size(); j++){
        //   PVector shadowDirection = lightVec;
        //   PVector shadowSource = new PVector(rayCollInfo.hitVec.x + shadowDirection.x*0.0001, rayCollInfo.hitVec.y + shadowDirection.y*0.0001, rayCollInfo.hitVec.z + shadowDirection.z*0.0001);
        //   float lParam = lightVec.mag();
        //   Ray shadowRay = new Ray(shadowSource, shadowDirection);
        //   RayCollInfo shadowIntersection = renderList.get(j).intersection(shadowRay);
        //   if(shadowIntersection.isHit && shadowIntersection.rootVal <= lParam)
        //   {
        //       shadows = true;
        //       j = renderList.size();
              
        //   }
        //}
        //if(shadows == false){
        //   //Diffuse color
        //   lightVec.normalize();
        //   rayCollInfo.normal.normalize();
        //   // (N.L)
        //   float NL = max(rayCollInfo.normal.dot(lightVec), 0);
        //   PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
        //   finalColor.x = finalColor.x + diffuseShading.x;
        //   finalColor.y = finalColor.y + diffuseShading.y;
        //   finalColor.z = finalColor.z + diffuseShading.z;
        //}
    }

    return finalColor;
}

public PVector createVec(PVector pt1, PVector pt2){
    return new PVector(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z);
}  

public Ray getRayAtPixel(int u, int v, boolean isCenter){
  
    Ray R = new Ray();
    float un,vn;
    //If single ray to center ( when 1 ray per pixel)
    if(isCenter){
        un = 0.5f; vn = 0.5f;
    } else {    // When multiple rays per pixel
        un = (float)Math.random();
        vn = (float)Math.random();
    }
    
    PVector origin = new PVector(0,0,0);
    PVector target = new PVector(camLeft + ((camRight-camLeft)*(v+vn)/width), camBottom+ ((camTop-camBottom)*(u+un)/height), -1.0f);
    PVector direction = new PVector(target.x - origin.x, target.y - origin.y, -1.0f); 
    //Normalizing the direction
    direction.normalize();
    R.origin = origin;
    R.direction = direction;
    return R;
}

public PVector computeColor(ArrayList<RenderObj> renderList, Ray currentRay){
  
    Ray newRay = new Ray();
    
    if(renderList.size() > 0)
    {  
      //If the depth of field is enabled
      if(setLens){

          //Our default lens / eye location is at origin
          PVector eyeLoc = new PVector(0,0,0);
          //Find intersection of the ray with the focal plane
          float inter = (-focalDistance - currentRay.origin.z)/(currentRay.direction.z);
          PVector FocalPoint = new PVector(currentRay.origin.x+inter*currentRay.direction.x,currentRay.origin.y+inter*currentRay.direction.y,currentRay.origin.z+inter*currentRay.direction.z);
          
          //Get a random point around they eye(lens)
          PVector eye = new PVector(0,0,0);
          float dr = sqrt((float)Math.random());
          float dt = 2*3.14157f*(float)Math.random();
          eye.x = eyeLoc.x + lensRadius*dr*cos(dt);
          eye.y = eyeLoc.y + lensRadius*dr*sin(dt);
          eye.z = eyeLoc.z;
          
          //get ray between random lens point and focal point
          PVector lf = createVec(eye,FocalPoint);
          
          newRay = new Ray(eye, lf); 
          //if(newRay.origin.x>4 || newRay.origin.x<-4)
  //          println(newRay.origin + "  " + newRay.direction);
      }
      else{
        newRay = currentRay;
          //Do nothing. DOn't change currentRay
      }
      int closestObj = firstIntersection(renderList, newRay);
      //No intersection happened
      if(closestObj == -1 )
      {  
          return backgroundColor;
      }
      else
      {
           RenderObj currentRenderObj = renderList.get(closestObj);
           RayCollInfo rayCollInfo = currentRenderObj.intersection(newRay);
           if(rayCollInfo.isHit)
           {
               return(getColor(lights,renderList,currentRenderObj, rayCollInfo));
           }
           else
           {
                return(backgroundColor);
           }
       }
    }
    return null;
}

 //public int closest_intersection( Ray R ) {
   
 //  objPt object_point = new objPt();
 //  object_point.objIndex = -1; // PROBABLY NOT NEEDED BUT JUST TO DEBUG  

 // // Init minDist
 //  mMinDist = 1000; 
 //  mMinInd = -1; 
 //  mMinNormal = new vec(0,0,0);

 // // Go through all primitives AFTER setting default minDist and minInd
 //  for( int i = 0; i < gEnv.mNumPrimitives; ++i ) {
 //    intersect( _R, i );
 //  }
   
 //  if( mMinInd != -1 ) { 
 //    object_point.objIndex = mMinInd; 
 //    object_point.P = mMinPoint; 
 //    object_point.N = mMinNormal.normalize();
 //  }
     
 //  return object_point;
 //}
 
//public boolean intersect( Ray R, int i ) {

 //  hitRecord rec; 
 //  rec = new hitRecord();
 
 // if( gEnv.mPrimitives[i].hit( _R, rec ) == true ) {
           
 //       if( rec.dist < mMinDist ) { 
 //          mMinDist = rec.dist; 
 //          mMinInd = i; 
 //          mMinPoint = rec.point; 
 //          mMinNormal = rec.normal;
 //        } // We normalize when assigning to mMinNormal
 //        return true;
 // }
    
//return false;
 
 //}
  public void settings() {  size (300, 300, P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "RayTracer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
