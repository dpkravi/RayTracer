// Bounding Box primitive class
class Box extends RenderObj {
  
  PVector minPt;
  PVector maxPt;

  Box() {
      super(boxType);
      minPt = new PVector(0,0,0);
      maxPt = new PVector(0,0,0);
  }

  /**< setBounds */
   void setBounds(PVector min, PVector max ) {
     minPt.x = min.x; 
     minPt.y = min.y; 
     minPt.z = min.z; 
     maxPt.x = max.x; 
     maxPt.y = max.y; 
     maxPt.z = max.z; 
   }
   
   void set( float xmin, float ymin, float zmin, float xmax, float ymax, float zmax ) {
     minPt.x = xmin; 
     minPt.y = ymin; 
     minPt.z = zmin; 
     maxPt.x = xmax; 
     maxPt.y = ymax; 
     maxPt.z = zmax; 
   }

  void copyData( Box box ) {

     minPt.x = box.minPt.x; 
     minPt.y = box.minPt.y; 
     minPt.z = box.minPt.z; 
     maxPt.x = box.maxPt.x; 
     maxPt.y = box.maxPt.y; 
     maxPt.z = box.maxPt.z; 
     
     material.diffuseCoeff.x = box.material.diffuseCoeff.x;
     material.diffuseCoeff.y = box.material.diffuseCoeff.y;
     material.diffuseCoeff.z = box.material.diffuseCoeff.z;
     material.ambientCoeff.x = box.material.ambientCoeff.x;
     material.ambientCoeff.y = box.material.ambientCoeff.y;
     material.ambientCoeff.z = box.material.ambientCoeff.z;

  }
  
  RayCollInfo intersection(Ray r) {

     float t1, t2, near, far;
     near = -1000;
     far = 1000;
     PVector nx = new PVector(0, 0, 0);
     PVector ny = new PVector(0, 0, 0);
     PVector nz = new PVector(0, 0, 0);
  
     PVector n = new PVector(0, 0, 0);
  
     float temp;
  
     // Plane in X    
     if (r.direction.x == 0) {
       if (r.origin.x < minPt.x || r.origin.x > maxPt.x) {
         return new RayCollInfo(false);
       }
     }
  
     t1 = (minPt.x - r.origin.x) / r.direction.x;
     t2 = (maxPt.x - r.origin.x) / r.direction.x;
  
     nx.x = -1;
     nx.y = 0;
     nx.z = 0;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       nx.x = +1;
       nx.y = 0;
       nx.z = 0;
     }
     if (t1 > near) {
       near = t1;
       n = nx;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     // Plane in Y
     if (r.direction.y == 0) {
       if (r.origin.y < minPt.y || r.origin.y > maxPt.y) {
         return new RayCollInfo(false);
       } 
     }
  
     t1 = (minPt.y - r.origin.y) / r.direction.y;
     t2 = (maxPt.y - r.origin.y) / r.direction.y;
  
     ny.x = 0;
     ny.y = -1;
     ny.z = 0;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       ny.x = 0;
       ny.y = +1;
       ny.z = 0;
     }
     if (t1 > near) {
       near = t1;
       n = ny;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     // Plane in Z
     if (r.direction.z == 0) {
       if (r.origin.z < minPt.z || r.origin.z > maxPt.z) {
         return new RayCollInfo(false);
       }
     }
  
     t1 = (minPt.z - r.origin.z) / r.direction.z;
     t2 = (maxPt.z - r.origin.z) / r.direction.z;
  
     nz.x = 0;
     nz.y = 0;
     nz.z = -1;
  
     if (t1 > t2) {
       temp = t2;
       t2 = t1;
       t1 = temp;
       nz.x = 0;
       nz.y = 0;
       nz.z = +1;
     }
     if (t1 > near) {
       near = t1;
       n = nz;
     }
     if (t2 < far) {
       far = t2;
     }
     if (near > far) {
       return new RayCollInfo(false);
     }
     if (far < 0) {
       return new RayCollInfo(false);
     }
  
     // Store collision info
     PVector hitPosition = new PVector(r.origin.x + near * r.direction.x, r.origin.y + near * r.direction.y, r.origin.z + near * r.direction.z);
     PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z);
     RayCollInfo rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, n, true, near);
  
     return rayCollInfo;


  }

  
};