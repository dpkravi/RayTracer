//This will be the base class from which shapes will be extended
class RenderObj
{
    Material material;
    int primitiveType;
    //Each primitive object will have a bounding box
    Box boundingBox;
    
    RenderObj() {
      primitiveType = base;
    }
    
    RenderObj(int primitiveType){
      this.primitiveType = primitiveType;
    }
    
    RenderObj(Material m, int base)
    {
        material = m;
        primitiveType = base;
    }
    
    RayCollInfo intersection(Ray r)
    {
      //For Debugging. Code will enter here only if primitive is not initialized. 
        println("Code should not enter here during proper execution");
        return null;  
    };
    
    int getPrimitiveType(){
      return primitiveType;
    }
    
    void setMaterial( Material m)
    {
        material = m;
    }
  
    boolean calcBoundingBox(){
       return false; 
    }
    
    //Returns the boundary dimensions as a float array 
    float[] getBoundingBoxDimensions(){
        float[] bboxdimensions = new float[6];
        bboxdimensions[0] = boundingBox.minPt.x; 
        bboxdimensions[1] = boundingBox.minPt.y; 
        bboxdimensions[2] = boundingBox.minPt.z;
        bboxdimensions[3] = boundingBox.maxPt.x;
        bboxdimensions[4] = boundingBox.maxPt.y; 
        bboxdimensions[5] = boundingBox.maxPt.z;   
        return bboxdimensions; 
    }
    
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
    
    public int noise;
    public int materialType; 
    
    public Material(PVector d, PVector a)
    {
        diffuseCoeff = d;
        ambientCoeff = a;
        noise = 0;
        materialType = noTex;
    }
    public Material(Material m)
    {
        diffuseCoeff = m.diffuseCoeff;
        ambientCoeff = m.ambientCoeff;
        noise = m.noise;
        materialType = m.materialType;
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
    int objIndex;
    
    //Adding this here because of issue with BVH. This is needed to set material for BVH object. 
    //Not used when acceleration is not used
    Material material;
    
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
        this.isTriangle = isTriangle;
    }
    public RayCollInfo(boolean isHit)
    {
        this.isHit = isHit;
    }
    
    void cloneData(RayCollInfo rayCollInfo) {
        reflVec = rayCollInfo.reflVec;
        hitVec = rayCollInfo.hitVec;
        normal = rayCollInfo.normal;
        isHit = rayCollInfo.isHit;
        rootVal = rayCollInfo.rootVal;
        material = rayCollInfo.material;
    }
}

class Sphere extends RenderObj
{
    PVector center;
    float radius;
    Sphere(float radius, PVector center, Material m)
    {
        super(m, sphere);
        this.radius = radius;
        this.center = center;
    }
    
    Sphere()
    {
        super();
        center = new PVector(0,0,0);
        radius = 1;
    }
    
    RayCollInfo intersection(Ray r)
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
            float RootD = pow(D, .5);
            // -l.(o-c)
            float minusB = -r.direction.dot(sphereVector);
            // Numerator -B +/- rootD
            float num = min(minusB - RootD, minusB - RootD);
            //root of quadratic equation
            float root = num/A;
            //If ray intersection happens then root will be a positive value
            if(root > 0.0000001)
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
    
    PVector getDiffuseColor(PVector pt) {
      float noise;
      
      //print(material.materialType+" ");
      
      // For noise
      if( material.noise != 0 ) {
          float f = material.noise;

          // The provided noise function generates values in the range [-1,1]. Adding 1 to move it to the [0,1] range
          noise = (1.0 + noise_3d(pt.x*f, pt.y*f, pt.z*f))/2.0;        
          
          PVector diffuseColor = new PVector(0,0,0);
          diffuseColor.x = material.diffuseCoeff.x*noise;
          diffuseColor.y = material.diffuseCoeff.y*noise;
          diffuseColor.z = material.diffuseCoeff.z*noise;
          return diffuseColor;
      }
      
     // For wood texture
     else if( material.materialType == woodTex ) {
     
       // Cylindric coordinates
       float s = atan2(pt.y, pt.x);
       if( s < 0 ) { 
           s =  s + 2.0*PI; 
       }
       s = s/(2*PI);
       float t = pt.z;
       t = abs(t)/radius;
              
       float r = sqrt(pt.x*pt.x + pt.y*pt.y);
       if( r > 1 && r < 1.0001 ) 
       { 
           r = 1; 
       } // clamp
       r = r / radius;

       float f = 1.0;
       float A = 0.45;
       noise = noise_3d( f*pt.x, f*pt.y, f*pt.z );      
       return woodColor(r + A*(noise));
       
     } 
     
      else {
          return material.diffuseCoeff;        
      }   
    }
    
    void cloneData( Sphere sphere ) {
        center.x = sphere.center.x;
        center.y = sphere.center.y;
        center.z = sphere.center.z;
        radius = sphere.radius;
        material = sphere.material;
    }
    
    //Not yet implemented
    boolean calcBoundingBox(){
       return false; 
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
    super(m, sphere);
    this.radius = radius;
    this.startPos = center1; 
    this.endPos = center2;
    this.speed = new PVector( endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z );
  //  this.center = new PVector( (startPos.x + endPos.x)/2, (startPos.z + endPos.z)/2, (startPos.z + endPos.z)/2);
  }
  
  RayCollInfo intersection(Ray r)
  {

      RayCollInfo rayCollInfo;

      float dt = (float)(Math.random());
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
          float RootD = pow(D, .5);
          float minusB = -r.direction.dot(sphereVector);
          float num = min(minusB - RootD, minusB - RootD);
          float root = num/A;
          if(root > 0.0000001)
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
        super(m, triangle);
        boundingBox = new Box();
        vertex1 = v1;
        vertex2 = v2;
        vertex3 = v3;
    }
    
    Triangle(){
        super(triangle);  
        boundingBox = new Box(); 
        vertex1 = new PVector(0,0,0);
        vertex2 = new PVector(0,0,0);
        vertex3 = new PVector(0,0,0);
    }
    
    RayCollInfo intersection(Ray r)
    {
      
       float epsilon = 0.0000001;
       //Two edges of triangle to calculate the normal
       PVector edge1 = createVec(vertex1,vertex3);
       PVector edge2 = createVec(vertex1,vertex2);
        
       //Cross product of the two edges gives the surface normal of the triangle
       PVector normal = edge1.cross(edge2);

       normal.normalize();
       
       // Invert the normals when they are flipped
       if(normal.dot(r.direction)>0){
          normal.mult(-1);
       }
        
       // Implementing the Möller–Trumbore intersection algorithm   -   https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
        
       //If ray direction and surface normal were perpendicular to each other then the ray is parallel to the surface
       if(r.direction.dot(normal) != 0)
       {
           PVector e1 = createVec(vertex2, vertex1);
           PVector e2 = createVec(vertex3, vertex1);
           PVector e3 = createVec(r.origin, vertex1); 
           PVector rayDir = new PVector(r.direction.x, r.direction.y, r.direction.z);
            
           PVector cross1 = new PVector(0.0,0.0,0.0);
           cross1.x = e2.y*rayDir.z - e2.z*rayDir.y;
           cross1.y = e2.z*rayDir.x - e2.x*rayDir.z;
           cross1.z = e2.x*rayDir.y - e2.y*rayDir.x;
            
           float det = e1.x*cross1.x + e1.y*cross1.y + e1.z*cross1.z;
            
           PVector cross2 = new PVector(0.0,0.0,0.0);
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
           
           RayCollInfo rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, normal, true, determinant);
           rayCollInfo.material = material;
           
           return rayCollInfo;
          
       }
       else
           return new RayCollInfo(false, true);
    }
    
    void cloneData(Triangle triangle){
        vertex1 = triangle.vertex1;
        vertex2 = triangle.vertex2;
        vertex3 = triangle.vertex3;
        material = triangle.material;
    }
    
    //Calculate the bounding box of the triangle
    boolean calcBoundingBox() { 
      boundingBox.minPt = new PVector(1000,1000,1000);
      boundingBox.maxPt = new PVector(-1000,-1000,-1000);
      
      //calculate minPt.x
      if (vertex1.x < boundingBox.minPt.x) {
          boundingBox.minPt.x = vertex1.x;
      }
      if (vertex1.x > boundingBox.maxPt.x) {
          boundingBox.maxPt.x = vertex1.x;
      }
      if (vertex2.x < boundingBox.minPt.x) {
          boundingBox.minPt.x = vertex2.x;
      }
      if (vertex2.x > boundingBox.maxPt.x) {
          boundingBox.maxPt.x = vertex2.x;
      }
      if (vertex3.x < boundingBox.minPt.x) {
          boundingBox.minPt.x = vertex3.x;
      }
      if (vertex3.x > boundingBox.maxPt.x) {
          boundingBox.maxPt.x = vertex3.x;
      }
      
    
      //calculate minPt.y
      if (vertex1.y < boundingBox.minPt.y) {
          boundingBox.minPt.y = vertex1.y;
      }
      if (vertex1.y > boundingBox.maxPt.y) {
          boundingBox.maxPt.y = vertex1.y;
      }
      if (vertex2.y < boundingBox.minPt.y) {
          boundingBox.minPt.y = vertex2.y;
      }
      if (vertex2.y > boundingBox.maxPt.y) {
          boundingBox.maxPt.y = vertex2.y;
      }
      if (vertex3.y < boundingBox.minPt.y) {
          boundingBox.minPt.y = vertex3.y;
      }
      if (vertex3.y > boundingBox.maxPt.y) {
          boundingBox.maxPt.y = vertex3.y;
      }
      
      
      //calculate minPt.z
      if (vertex1.z < boundingBox.minPt.z) {
          boundingBox.minPt.z = vertex1.z;
      }
      if (vertex1.z > boundingBox.maxPt.z) {
          boundingBox.maxPt.z = vertex1.z;
      }
      if (vertex2.z < boundingBox.minPt.z) {
          boundingBox.minPt.z = vertex2.z;
      }
      if (vertex2.z > boundingBox.maxPt.z) {
          boundingBox.maxPt.z = vertex2.z;
      }
      if (vertex3.z < boundingBox.minPt.z) {
          boundingBox.minPt.z = vertex3.z;
      }
      if (vertex3.z > boundingBox.maxPt.z) {
          boundingBox.maxPt.z = vertex3.z;
      }
      return true; 
    }
}

//Matrix stack used to store the transformation matrices
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