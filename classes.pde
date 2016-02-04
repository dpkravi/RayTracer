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
    float rootVal;
    public RayCollInfo (PVector reflVec, PVector hitVec,PVector normal, boolean isHit, float rootVal)
    {
        this.reflVec = reflVec;
        this.hitVec = hitVec;
        this.normal = normal;
        this.isHit = isHit;
        this.rootVal = rootVal;
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