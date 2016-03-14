// Bounding Box primitive class
class Box extends RenderObj {

  PVector minPt;
  PVector maxPt;

  Box() {
    super(bbox);
    minPt = new PVector(0, 0, 0);
    maxPt = new PVector(0, 0, 0);
  }

  void set( float xmin, float ymin, float zmin, float xmax, float ymax, float zmax, Material mat ) {
    
    minPt = new PVector(xmin,ymin,zmin);
    maxPt = new PVector(xmax,ymax,zmax);
    material = mat;
  }

  void copyData( Box box ) {

    minPt = new PVector(box.minPt.x,box.minPt.y,box.minPt.z);
    maxPt = new PVector(box.maxPt.x,box.maxPt.y,box.maxPt.z);
    material = box.material;
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

    if (n.dot(r.direction)>0) {
      n.mult(-1);
    }
    
    // Store collision info
    PVector hitPosition = new PVector(r.origin.x + near * r.direction.x, r.origin.y + near * r.direction.y, r.origin.z + near * r.direction.z);
    PVector reflectionVector = new PVector(-r.direction.x, -r.direction.y, -r.direction.z);
    RayCollInfo rayCollInfo = new RayCollInfo(reflectionVector, hitPosition, n, true, near);

    return rayCollInfo;
  }
};

class Instance extends RenderObj {

  int  index;
  PMatrix3D tMat;
  PMatrix3D invMat;

  Instance() {
    super( instance );
    index = -1; 
    tMat = new PMatrix3D();
    invMat = new PMatrix3D();
  }

  Instance( int index, PMatrix3D transMatrix ) {
    super( instance );
    this.index = index; 
    tMat = transMatrix.get();
    invMat = tMat.get(); 
    invMat.invert();
    material = namedRenderObjs.get(index).material;
  }

  RayCollInfo intersection( Ray R ) {
    PVector tgt = new PVector();
    PVector p1 = new PVector( R.origin.x, R.origin.y, R.origin.z );
    float[] p2 = new float[4]; 
    p2[0] = R.direction.x; 
    p2[1] = R.direction.y; 
    p2[2] = R.direction.z; 
    p2[3] = 0;
    float[] tgt2 = new float[4];
    invMat.mult( p1, tgt ); 
    invMat.mult( p2, tgt2 );

    PVector P2 = new PVector(tgt.x, tgt.y, tgt.z);
    PVector V2 = new PVector(tgt2[0], tgt2[1], tgt2[2]);

    //ray newR = Minv*a + t.Minv*b
    Ray ray = new Ray(P2, V2); 

    RayCollInfo rCInfo= namedRenderObjs.get(index).intersection(ray);
    if ( rCInfo.isHit == true ) {

      PMatrix3D inv1 = invMat.get(); 
      inv1.transpose();
      PVector p3 = new PVector( R.origin.x + R.direction.x*rCInfo.rootVal, R.origin.y + R.direction.y*rCInfo.rootVal, R.origin.z + R.direction.z*rCInfo.rootVal );
      rCInfo.hitVec = new PVector(p3.x, p3.y, p3.z);

      PVector n4 = new PVector( rCInfo.normal.x, rCInfo.normal.y, rCInfo.normal.z );
      PVector tgt4 = new PVector();
      
      //newNormal = Transpose(Minv)*normal
      inv1.mult(n4, tgt4);
      rCInfo.normal.x = tgt4.x; 
      rCInfo.normal.y = tgt4.y; 
      rCInfo.normal.z = tgt4.z;
    }

    return rCInfo;
  }

  void cloneData( Instance instance ) {
    index = instance.index;
    tMat = instance.tMat;
    invMat = instance.invMat;
    material = instance.material;
  }
}  


class List extends RenderObj {

  int listSize;
  ArrayList<RenderObj> listObjects;


  List() {
    super(listType);
    boundingBox = new Box();
    listSize = 0;
    listObjects = new ArrayList<RenderObj>();
  }

  void cloneData( List list ) {
    listSize = 0;
    for ( int i = 0; i < listSize; ++i ) {
      if ( list.listObjects.get(i).getPrimitiveType() == triangle ) { 
        addToList((Triangle) list.listObjects.get(i) );
      }      
      //Add spheres and other types too. Not necessary for current data files.
    }
    material = list.material;
  }

  void addToList(RenderObj renderObj) {

    if ( renderObj.getPrimitiveType() == sphere ) {
      listObjects.add((Sphere)renderObj);
    } else if (renderObj.getPrimitiveType() == triangle ) {
      listObjects.add((Triangle)renderObj);
    } else if (renderObj.getPrimitiveType() == instance ) {
      listObjects.add((Instance)renderObj);
    } else if (renderObj.getPrimitiveType() == bbox ) {
      listObjects.add((Box)renderObj);
    } else if (renderObj.getPrimitiveType() == listType ) {
      listObjects.add((List)renderObj);
    }    
    listSize++;
  }

  int getSize() {
    return listSize;
  }

  boolean calcBoundingBox() {

    boundingBox.minPt = new PVector(1000,1000,1000);
    boundingBox.maxPt = new PVector(-1000,-1000,-1000); 

    float[] bboxdims = new float[6];

    // Loop through all bounding boxes of the list objects and calculate the bounding box for this list as a whole
    for ( int i = 0; i < listSize; i++ ) {
      
      listObjects.get(i).calcBoundingBox();
      bboxdims = listObjects.get(i).getBoundingBoxDimensions();
      
      if (boundingBox.minPt.x > bboxdims[0]) {
        boundingBox.minPt.x = bboxdims[0];
      }
      if (boundingBox.minPt.y > bboxdims[1]) {
        boundingBox.minPt.y = bboxdims[1];
      }
      if (boundingBox.minPt.z > bboxdims[2]) {
        boundingBox.minPt.z = bboxdims[2];
      }
      if (boundingBox.maxPt.x < bboxdims[3]) {
        boundingBox.maxPt.x = bboxdims[3];
      }
      if (boundingBox.maxPt.y < bboxdims[4]) {
        boundingBox.maxPt.y = bboxdims[4];
      }
      if (boundingBox.maxPt.z < bboxdims[5]) {
        boundingBox.maxPt.z = bboxdims[5];
      }
    } 

    return true;
  }

  RayCollInfo intersection(Ray R) {
    RayCollInfo rayCollInfo = new RayCollInfo(false);
    RayCollInfo boundingBoxHit = boundingBox.intersection(R);
    //First find if the bounding box is hit. If it is not hit then the whole list can be skipped and execution is faster
    if(boundingBoxHit.isHit){
      double smallestDist = 1000;
      int closestIndex = -1;
      boolean hit = false;
      //For each element in the list, intersect with the ray and find the closest hit. 
      for(int i = 0; i < listSize; i++ ) {
        RayCollInfo objectHit = ( (Triangle) listObjects.get(i)).intersection(R);
        if ( objectHit.isHit ) {
          hit = true;
          if ( objectHit.rootVal < smallestDist ) {
            smallestDist = objectHit.rootVal;
            closestIndex = i;
            rayCollInfo = objectHit;
          }
        }
      }

      if (hit) {
        material = listObjects.get(closestIndex).material;
      }
      return rayCollInfo;
    } else {
      return new RayCollInfo(false);
    }
  }
};



class BVH extends RenderObj {

  public int axis;
  public RenderObj leftObj;
  public RenderObj rightObj;

  BVH(RenderObj[] objects, int a) {
    super(bvhType);
    boundingBox = new Box();
    axis = a;
    leftObj = new RenderObj();
    rightObj = new RenderObj();
    calcBoundingBox(objects);

    //Currently coded only for triangles. 
    if ( objects.length == 1 ) {
      leftObj = (Triangle) objects[0];
      material = leftObj.material; 
    } else if ( objects.length == 2 ) {
      leftObj = (Triangle) objects[0];
      rightObj = (Triangle) objects[1];

    } else {  
      //Recursively construct the BVH tree
      ArrayList<ArrayList<Triangle>> partitions = partitionAtAxis(objects); 
      if ( partitions.get(0).size() > 0 ) {
        leftObj = new BVH( partitions.get(0).toArray(new RenderObj[partitions.get(0).size()]), (axis+1)%3);
      }  
      if ( partitions.get(1).size() > 0 ) { 
        rightObj = new BVH( partitions.get(1).toArray(new RenderObj[partitions.get(1).size()]), (axis+1)%3);
      }
    }
  }

  boolean calcBoundingBox(RenderObj[] objects) {

    boundingBox.minPt = new PVector(1000,1000,1000);
    boundingBox.maxPt = new PVector(-1000,-1000,-1000);

    float[] bboxdims = new float[6];

    for ( int i = 0; i < objects.length; i++ ) {
      bboxdims = objects[i].getBoundingBoxDimensions();
      if (boundingBox.minPt.x > bboxdims[0]) {
        boundingBox.minPt.x = bboxdims[0];
      }
      if (boundingBox.minPt.y > bboxdims[1]) {
        boundingBox.minPt.y = bboxdims[1];
      }
      if (boundingBox.minPt.z > bboxdims[2]) {
        boundingBox.minPt.z = bboxdims[2];
      }
      if (boundingBox.maxPt.x < bboxdims[3]) {
        boundingBox.maxPt.x = bboxdims[3];
      }
      if (boundingBox.maxPt.y < bboxdims[4]) {
        boundingBox.maxPt.y = bboxdims[4];
      }
      if (boundingBox.maxPt.z < bboxdims[5]) {
        boundingBox.maxPt.z = bboxdims[5];
      }
    }  
    return true;
  }

  //Did only mid point splitting. No surface area heuristics 
  ArrayList<ArrayList<Triangle>> partitionAtAxis( RenderObj[] objects ) {
    ArrayList<ArrayList<Triangle>> partitions = new ArrayList<ArrayList<Triangle>>();
    // Find midPt: Middle point in axis. Split the bounding box into two
    float midPt = 0;
    int n = objects.length;

    if (axis == 0)  // X-Axis
      midPt = (boundingBox.minPt.x + boundingBox.maxPt.x)/2.0; 
    else if (axis == 1)  // Y-Axis
      midPt = (boundingBox.minPt.y + boundingBox.maxPt.y)/2.0;  
    else if (axis == 2)   // Z-Axis 
      midPt = (boundingBox.minPt.z + boundingBox.maxPt.z)/2.0;  
      
    ArrayList<Triangle> leftTriangles = new ArrayList<Triangle>();
    ArrayList<Triangle> rightTriangles = new ArrayList<Triangle>();    
    
    //Find the centroid of each primitive and compare with the midPt calculated above
    //Currently works only for triangle 
    float c = 0;
    for ( int i = 0; i < n; ++i ) {
      if (axis == 0)
        c = (objects[i].boundingBox.maxPt.x + objects[i].boundingBox.minPt.x)/2.0;
      else if (axis == 1)
        c = (objects[i].boundingBox.maxPt.y + objects[i].boundingBox.minPt.y)/2.0;
      else if (axis == 2)
        c = (objects[i].boundingBox.maxPt.z + objects[i].boundingBox.minPt.z)/2.0;

      //if c<midPt then object is to the left of the split
      if ( c < midPt ) { 
          leftTriangles.add((Triangle)objects[i]);
      } else {  // the object is to the right of the split
          rightTriangles.add((Triangle)objects[i]); 
      }
    }
    partitions.add(leftTriangles);
    partitions.add(rightTriangles);
    return partitions;
  }


  RayCollInfo intersection(Ray R) { 

    RayCollInfo rayCollInfo = boundingBox.intersection(R);
    if (rayCollInfo.isHit) {
      
      RayCollInfo leftIntersection = new RayCollInfo(false);
      RayCollInfo rightIntersection = new RayCollInfo(false);

      boolean isLeftHit, isRightHit;

      if(leftObj.primitiveType!=0) {
        leftIntersection = leftObj.intersection(R);
        isLeftHit = leftIntersection.isHit;
      }
      else 
        isLeftHit = false; 
        
      if(rightObj.primitiveType!=0){
        rightIntersection = rightObj.intersection(R);
        isRightHit = rightIntersection.isHit;
      }
      else
        isRightHit = false;
      //If both intersect then find the closest intersection
      if ( isLeftHit && isRightHit ) {
        if ( leftIntersection.rootVal < rightIntersection.rootVal ) {
          rayCollInfo.cloneData(leftIntersection);
        } else {
          rayCollInfo.cloneData(rightIntersection);
        }  
        //set material for the BVH node. This will be used when rendering
        material = rayCollInfo.material;
        return rayCollInfo;
      } else if (isLeftHit) {
         rayCollInfo.cloneData(leftIntersection);
        material = rayCollInfo.material;
        return rayCollInfo;
      } else if ( isRightHit ) {
        rayCollInfo.cloneData(rightIntersection);
        material = rayCollInfo.material;
        return rayCollInfo;
      } else {
        //No intersection
        return new RayCollInfo(false);
      }
    } 
    //No intersection
    else {
      return new RayCollInfo(false);
    }
  }

};  