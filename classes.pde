//This will be the base class from which shapes will be extended
//Currently only spheres are used. 
abstract class RenderObj
{
    Material material;
    RenderObj(Material m)
    {
        material = m;
    }
    abstract RayCollInfo intersection(Ray r);
}

class Light
{
    PVector position;
    PVector colour;
    public Light(PVector position,PVector colour)
    {
        this.position = position;
        this.colour = colour;
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