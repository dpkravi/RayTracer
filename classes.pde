//This will be the base class from which shapes will be extended
class RenderObj
{
    Material material;
    int primitiveType;
    
    Box boundingBox;
    
    RenderObj() {
      primitiveType = defaultType;
    }
    
    RenderObj(int primitiveType){
      this.primitiveType = primitiveType;
    }
    
    RenderObj(Material m, int primitiveType)
    {
        material = m;
        primitiveType = defaultType;
    }

    void cloneData( RenderObj renderObj ) {};
    
    RayCollInfo intersection(Ray r)
    {
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
    
    float[] getBoundingBoxDimensions(){
        float[] bboxdims = new float[6];
        bboxdims[0] = boundingBox.minPt.x; 
        bboxdims[1] = boundingBox.minPt.y; 
        bboxdims[2] = boundingBox.minPt.z;
        bboxdims[3] = boundingBox.maxPt.x;
        bboxdims[4] = boundingBox.maxPt.y; 
        bboxdims[5] = boundingBox.maxPt.z;   
        return bboxdims; 
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
    int objIndex;
    
    //Adding this temporarily
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
}

class Sphere extends RenderObj
{
    PVector center;
    float radius;
    Sphere(float radius, PVector center, Material m)
    {
        super(m, sphereType);
        this.radius = radius;
        this.center = center;
    }
    
    Sphere()
    {
        super(sphereType);
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
    
    void cloneData( Sphere sphere ) {
        center.x = sphere.center.x;
        center.y = sphere.center.y;
        center.z = sphere.center.z;
        radius = sphere.radius;
        
        material = sphere.material;
    }
    
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
    super(m, sphereType);
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
        super(m, triangleType);
        boundingBox = new Box();
        vertex1 = v1;
        vertex2 = v2;
        vertex3 = v3;
    }
    
    Triangle(){
        super( triangleType );  
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
       //PVector edge1 = new PVector(vertex3.x - vertex1.x, vertex3.y - vertex1.y, vertex3.z - vertex1.z);
       //PVector edge2 = new PVector(vertex2.x - vertex1.x, vertex2.y - vertex1.y, vertex2.z - vertex1.z);
        
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
    
    //Calculate the bounding box
    boolean calcBoundingBox() { 
      boundingBox.minPt.x = 1000; 
      boundingBox.minPt.y = 1000; 
      boundingBox.minPt.z = 1000;
      boundingBox.maxPt.x = -1000;
      boundingBox.maxPt.y = -1000;
      boundingBox.maxPt.z = -1000;
      
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

public class PrimitiveStack {
  int size = 0;
  RenderObj renderObjects[];
  static final int max = 70000;

  PrimitiveStack() {
      renderObjects = new RenderObj[max];
      for(int i=0; i<max; ++i) {
        renderObjects[i] = new RenderObj();
      }
  }
  
  void push(RenderObj renderObj) {
      if(size == renderObjects.length) {
        print("Object Stack capacity exceeded");
        return;
      }   
      if( renderObj.getPrimitiveType() == triangleType ) {
         renderObjects[size] = new Triangle();
        ((Triangle) renderObjects[size]).cloneData( (Triangle) renderObj );  
      } 
      else{
         println("Not adding anything");
      }
      size++;
  }
  
  public RenderObj pop() {
      RenderObj renderObj = new RenderObj(); 
      if( renderObjects[size - 1].getPrimitiveType() == triangleType ) {
        renderObj = new Triangle();
        ((Triangle) renderObj).cloneData((Triangle)renderObjects[size - 1]);
      } 
    size--;
      
    return renderObj;
  }
  
  public int getSize() {
      return size; 
  }
};