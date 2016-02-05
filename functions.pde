int firstIntersection(ArrayList<RenderObj> renderList, Ray currentRay)
{

    ArrayList<Integer> collList = new ArrayList<Integer>();
    //Create a list of all the ray object intersections for this particular ray
    if(test1){
      println(renderList.size());
      test1 = false;
    }
    for(int i = 0; i < renderList.size(); i++)
    {
        RenderObj newRenderable = renderList.get(i);
        RayCollInfo newRayCollInfo = newRenderable.intersection(currentRay);
        if(newRayCollInfo.isHit)
        {
            collList.add(i);
        }
    }
    //if(collList.size() == 0)
    //  println("worstu");
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

PVector getColor(ArrayList<Light> lights, ArrayList<RenderObj> renderList, RenderObj currentObj, RayCollInfo rayCollInfo)
{
   
    //Ambient color
    PVector finalColor = new PVector(currentObj.material.ambientCoeff.x, currentObj.material.ambientCoeff.y, currentObj.material.ambientCoeff.z);
    for(int i = 0; i < lights.size(); i++)
    {
        shadows = false;
        Light currentLight = lights.get(i);
        PVector lightVec = new PVector(currentLight.position.x - rayCollInfo.hitVec.x, currentLight.position.y - rayCollInfo.hitVec.y, currentLight.position.z - rayCollInfo.hitVec.z);
        for( int j = 0; j< renderList.size(); j++){
            PVector shadowDirection = lightVec;
            PVector shadowSource = new PVector(rayCollInfo.hitVec.x + shadowDirection.x*0.0001, rayCollInfo.hitVec.y + shadowDirection.y*0.0001, rayCollInfo.hitVec.z + shadowDirection.z*0.0001);
            float lParam = lightVec.mag();
            Ray shadowRay = new Ray(shadowSource, shadowDirection);
            RayCollInfo shadowIntersection = renderList.get(j).intersection(shadowRay);
            if(shadowIntersection.isHit && shadowIntersection.rootVal <= lParam)
            {
                shadows = true;
                ///////////////////FIND DIFFERENT WAY TO BREAK OUT OF LOOP
                j = renderList.size();
              
            }
        }
        if(shadows == false){
            //Diffuse color
            lightVec.normalize();
            rayCollInfo.normal.normalize();
            // (N.L)
            float NL = max(rayCollInfo.normal.dot(lightVec), 0);
            PVector diffuseShading = new PVector( currentObj.material.diffuseCoeff.x*currentLight.colour.x*NL, currentObj.material.diffuseCoeff.y*currentLight.colour.y*NL, currentObj.material.diffuseCoeff.z*currentLight.colour.z*NL);
            finalColor.x = finalColor.x + diffuseShading.x;
            finalColor.y = finalColor.y + diffuseShading.y;
            finalColor.z = finalColor.z + diffuseShading.z;
        }
    }
    return finalColor;
}

PVector createVec(PVector pt1, PVector pt2){
    return new PVector(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z);
}  

float[][] matrixMult(float[][] A, float[][] B) {
    int mA = A.length;
    int nA = A[0].length;
    int mB = B.length;
    int nB = B[0].length;
    if (nA != mB) throw new RuntimeException("Illegal matrix dimensions.");
    float[][] C = new float[mA][nB];
    for (int i = 0; i < mA; i++)
        for (int j = 0; j < nB; j++)
            for (int k = 0; k < nA; k++)
                C[i][j] += A[i][k] * B[k][j];
    return C;
}

float [][] createTranslateMat(float t1, float t2, float t3){
    float[][] result = new float[][]{
      { 1, 0, 0, t1},
      { 0, 1, 0, t2},
      { 0, 0, 1, t3},
      { 0, 0, 0, 1},
    };
    //println("The Translation Matrix");
    //printMat(result);
    return result;
}

float [][] createScaleMat(float s1, float s2, float s3){
    float[][] result = new float[][]{
      { s1, 0, 0, 0},
      { 0, s2, 0, 0},
      { 0, 0, s3, 0},
      { 0, 0, 0, 1},
    };
    //println("The Scaling Matrix");
    //printMat(result);
    return result;
}

float [][] createRotateMat(float angleInDegrees, float u, float v, float w){
    float[][] result = new float[][]{
      { 0, 0, 0, 0},
      { 0, 0, 0, 0},
      { 0, 0, 0, 0},
      { 0, 0, 0, 1},
    };
    float angle = ((angleInDegrees * PI)/180.0);
    result[0][0] = u*u + (1-u)*(1-u)*cos(angle);        
    result[0][1] = u*v*(1-cos(angle)) - w*sin(angle);      
    result[0][2] = u*w*(1-cos(angle))+v*sin(angle);
    result[1][0] = u*v*(1-cos(angle)) + w*sin(angle);
    result[1][1] = v*v + (1-v)*(1-v)*cos(angle); 
    result[1][2] = v*w*(1-cos(angle))-u*sin(angle);
    result[2][0] = u*w*(1-cos(angle))-v*sin(angle);
    result[2][1] = v*w*(1-cos(angle))+u*sin(angle);
    result[2][2] = w*w + (1-w)*(1-w)*cos(angle); 
    //println("The Rotation Matrix");
    //printMat(result);
    return result;
}

void printMat(float[][] matrix){
  int rows = matrix.length;
  int columns = matrix[0].length;
  for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
          System.out.print(matrix[i][j] + "\t");
      }
      System.out.print("\n");
  }
}