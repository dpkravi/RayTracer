public class Sphere extends RenderObj {
  
  float radius;
  PVector center;
  
  public Sphere(float radius, PVector center, Material material){
    addMaterial(material);
    this.radius = radius;
    this.center = center;
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
                //PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z );
                PVector hitPosition = new PVector(r.direction.x, r.direction.y, r.direction.z);
                hitPosition.mult(root);
                hitPosition.add(r.origin);
                // Find the normal vector to the sphere at (x, y, z)
                PVector normal = new PVector((hitPosition.x - center.x)/radius, (hitPosition.y - center.y)/radius, (hitPosition.z - center.z)/radius);
                rayCollInfo = new RayCollInfo(root, normal, hitPosition, this);
                return rayCollInfo;
            }
            // No intersection happened
            else
            {
                rayCollInfo = new RayCollInfo(-1, null);
                return rayCollInfo;
            }
        }
        // no intersection happened
        else
        {
            rayCollInfo = new RayCollInfo(-1, null);
            return rayCollInfo;
        }
    }
  
 
}

public class Triangle extends RenderObj {
  
  private PVector vertex1;
  private PVector vertex2;
  private PVector vertex3;
  
  public Triangle(PVector v1, PVector v2, PVector v3, Material material){
    addMaterial(material);
    this.vertex1 = v1;
    this.vertex2 = v2;
    this.vertex3 = v3;

  }
  
  public RayCollInfo intersection(Ray ray){

   PVector edge1 = createVec(vertex1,vertex2);
   PVector edge2 = createVec(vertex1,vertex3);
 
   PVector normal = new PVector();
   normal = edge1.cross(edge2);
   normal.normalize();

   float isParallel = ray.direction.dot(normal);
   //plane is parallel to ray
   if(isParallel == 0){
     return new RayCollInfo(-1, null);
   }
   
   float plane = -normal.dot(vertex1);
   float time = -(normal.dot(ray.origin) + plane)/(isParallel);
    
   PVector collision = ray.hit(time);

   PVector vert1coll = createVec(vertex1,collision);
   PVector vert2coll = createVec(vertex2,collision);
   PVector vert3coll = createVec(vertex3,collision);
    
   PVector vec12 = createVec(vertex1, vertex2);
   PVector vec23 = createVec(vertex2, vertex3); 
   PVector vec31 = createVec(vertex3, vertex1); 
   
    //The intersection lies outside of the triangle 
   if(vec12.cross(vert1coll).dot(normal)<0){
    return new RayCollInfo(-1, null);
   }
    //The intersection lies outside of the triangle
   if(vec23.cross(vert2coll).dot(normal)<0){
    return new RayCollInfo(-1, null);
   }
    //The intersection lies outside of the triangle
   if(vec31.cross(vert3coll).dot(normal)<0){
    return new RayCollInfo(-1, null);
   }
   PVector hitVec = ray.hit(time);
   
   return new RayCollInfo(time, normal, hitVec, this);
  }
    

}


public class Hollow_Cylinder extends RenderObj{
  
  float radius;
  PVector position;
  float ymax;
  
  public Hollow_Cylinder(float radius, PVector position, float ymax, Material material){
    addMaterial(material);
    this.radius = radius;
    this.position = position;
    this.ymax = ymax;

  }
 
  public RayCollInfo intersection(Ray ray){
    // Used these slides for reference : http://mrl.nyu.edu/~dzorin/rend05/lecture2.pdf
    PVector origin = ray.origin;
    PVector direction = ray.direction;
    PVector ctrToOrg = createVec(position, origin);
    float a = sq(direction.x) + sq(direction.z);
    float b = 2*direction.x*(ctrToOrg.x) + 2*direction.z*(ctrToOrg.z);
    float c = sq(ctrToOrg.x) + sq(ctrToOrg.z) - sq(radius);
    float discriminant = sq(b) - (4.0*a*c);
        
    if(discriminant < 0){
      return new RayCollInfo(-1, null);
    }
    
     //Find the roots. THese are the two times that it will hit the cylinder
    float plus = (-1.0*b+sqrt(discriminant))/(2.0*a);
    float minus = (-1.0*b-sqrt(discriminant))/(2.0*a);
    
    float y1 = origin.y + minus*direction.y;
    float y2 = origin.y + plus*direction.y;
    float ymin = position.y; float minTime = -1;

    if(ymin <= y1 && y1 <= ymax && ymin <= y2 && y2 <= ymax){
      minTime = smallest(minus, plus);
    }
    else if(ymin <= y2 && y2 <= ymax){
       minTime = plus;
    }
    else if(ymin <= y1 && y1 <= ymax){
       minTime = minus;
    }
    if(minTime == -1){
      return new RayCollInfo(minTime, null);
    }
    PVector intersection_point = ray.hit(minTime);
    
    PVector normal1 = new PVector(position.x, intersection_point.y, position.z);
    PVector cylinderNormal = createVec(normal1, intersection_point);
    return new RayCollInfo(minTime, cylinderNormal, intersection_point, this);
  }
  

  
}