import java.util.List;
public class Light{
  
 PVector position;
 PVector colour;
  
 Light(PVector position, PVector colour){
   this.position = position;
   this.colour = colour;
 }
   
}

public class Material{
  PVector diffuseCoeff;
  PVector ambientCoeff;
  float KRef = 0;
  
  public Material(PVector diffuseCoeff, PVector ambientCoeff){
    this.diffuseCoeff = diffuseCoeff;
    this.ambientCoeff = ambientCoeff;
    KRef = 0;
  }
  public Material(PVector diffuseCoeff, PVector ambientCoeff, float Kref){
    this.diffuseCoeff = diffuseCoeff;
    this.ambientCoeff = ambientCoeff;
    this.KRef = Kref;
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
}

public abstract class RenderObj{
  
  Material material;
  
  abstract RayCollInfo intersection(Ray ray);
   
  public void addMaterial(Material material){
    this.material = material;
  }

}

public class RayCollInfo{
  
  float time;
  PVector normal;
  PVector hitVec;
  RenderObj obj = null;
  
  public RayCollInfo(float time, PVector normal){
    this.time = time;
    this.normal = normal;
    hitVec = null;
  }
  
  public RayCollInfo(float time, PVector normal, PVector hitVec){
    this.time = time;
    this.normal = normal;
    this.hitVec = hitVec;
  }
  
  public RayCollInfo(float time, PVector normal, PVector hitVec, RenderObj obj){
    this.time = time;
    this.normal = normal;
    this.hitVec = hitVec;
    this.obj = obj;
  }
  
}

public class Ray{
  
  PVector origin;
  PVector direction;
  
  Ray(){
    origin = new PVector();
    direction = new PVector();
  }
  
  public Ray(PVector origin, PVector direction){
    this.origin = origin;
    this.direction = direction;
  }

  public PVector hit(float time){
    return new PVector(origin.x + time*direction.x, origin.y + time*direction.y, origin.z + time*direction.z);
  }
}