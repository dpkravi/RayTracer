void getColor(){
  loadPixels();
  Ray currentRay = new Ray();
  float fovInRadians = tan(radians(fov/2.0));
  float xMid = fovInRadians/width;
  float yMid = fovInRadians/height;
  
  for(int u = 0; u < width; u+=1){
    float x1 = ((2.0*fovInRadians/width)*u)-fovInRadians;
    for(int v = 0; v < height; v+=1){
      PVector finalColor = new PVector();
      float y1 = ((-2.0*fovInRadians/height)*v)+fovInRadians;
      
      float xPos = x1 + xMid;
      float yPos = y1 + yMid;
      float magnitude = sqrt(sq(xPos-currentRay.origin.x) + sq(yPos-currentRay.origin.y) + 1);
      currentRay.direction = new PVector((xPos-currentRay.origin.x)/magnitude, (yPos-currentRay.origin.y)/magnitude, -1/magnitude);

      finalColor.add(computeColor(currentRay, null));

      // Convert the color array for updating Pixels to screen
      for(int i = u; i < u + 1; i++){
        for(int j = v; j< v + 1; j++){
          if(j*width+i < width*height){
            pixels[j*width+i] = color(finalColor.x, finalColor.y, finalColor.z);
          }
        }
      }
    }
  }
  updatePixels();
}


public PVector computeColor(Ray ray, RenderObj closestObj){
  
  PVector finalColor = new PVector();
  
  float min = 99999;
  
  RenderObj firstObj = null;
  RayCollInfo rayCollInfo = null;

  // Get the collision info for the closest object for this ray.
  for(int i=0; i< renderList.size(); i++){
    if(renderList.get(i) != closestObj){
      RayCollInfo curRayCollInfo = renderList.get(i).intersection(ray);
      if(curRayCollInfo.time >= 0 && curRayCollInfo.time < min){
        min = curRayCollInfo.time;
        rayCollInfo = curRayCollInfo;
      }
    }
  }
  
  //If a collision did occur
  if(rayCollInfo!=null){
    //Get object from collision info
    firstObj = rayCollInfo.obj;
    Material currMaterial = firstObj.material;
    PVector diffuseCoeff = currMaterial.diffuseCoeff;
    PVector ambientCoeff = currMaterial.ambientCoeff;

    //Add the ambient color to the final color
    finalColor.add(ambientCoeff);
    
    //Normalize the collision normal
    rayCollInfo.normal.normalize();
    
    // If caustic photon mapping is enabled. Tree should have already been generated
    if(caustic){
     //Get a list of the nearby photons by searching the KD-tree
         ArrayList<Photon> plist = photons.find_near(rayCollInfo.hitVec.x, rayCollInfo.hitVec.y, rayCollInfo.hitVec.z, num_near, max_near_dist);
         float max_dist = 0;
         float flux = 0;
         if(plist != null){
             for(Photon p : plist){
                 if(p!=null){
                   //adding photon ith power
                   flux+=abs(p.powerR);
                   float curr_dist = sqrt((pow(rayCollInfo.hitVec.x-p.pos[0],2))+(pow(rayCollInfo.hitVec.y-p.pos[1],2))+(pow(rayCollInfo.hitVec.z-p.pos[2],2)));
                   if(curr_dist > max_dist){
                     max_dist = curr_dist;
                   }
               }
           }
           //irradiance  = flux/area
           float irradiance = flux/(2*(float)Math.PI*max_dist*max_dist);
           if(max_dist!=0){
             //multiplying the irradiance value by 8 to increase the intensity of the color
             finalColor.add(new PVector(irradiance, irradiance, irradiance).mult(8));
           }
       }
    }

    // Calculate the diffuse lighting
    for(int i=0; i< lights.size(); i++){
      Light light = lights.get(i);
      Ray lightRay = new Ray();
      PVector lightPosition = light.position;
      PVector objToLight = createVec(rayCollInfo.hitVec, lightPosition);
      objToLight.normalize();
        
      PVector firstHitToOrigin = createVec(rayCollInfo.hitVec, ray.origin);
      firstHitToOrigin.normalize();
      
      float normalAlign = rayCollInfo.normal.dot(objToLight);
      float normal = rayCollInfo.normal.dot(ray.direction);
      
      //If it is a triangle, invert the normals in case it is flipped
            
      if(normal > 0 && firstObj.getClass().equals(Triangle.class)){
        rayCollInfo.normal = rayCollInfo.normal.mult(-1);
        normalAlign = rayCollInfo.normal.dot(objToLight);
      }
      
      //If it is a hollow cylinder, invert the normals in case it is flipped
      if(normal > 0 && firstObj.getClass().equals(Hollow_Cylinder.class)){
       rayCollInfo.normal = rayCollInfo.normal.mult(-1);
       normalAlign = rayCollInfo.normal.dot(objToLight);
      }
      
      float diffuse = max(0, normalAlign);
      PVector diffuseColor = new PVector(diffuseCoeff.x*diffuse, diffuseCoeff.y*diffuse, diffuseCoeff.z*diffuse);
      // Calculating the shadows and diffuse lighting
      float dist = 0;
      float shadeTime = 99999;
      RenderObj shadowObj = null;
      RayCollInfo shadowIntersection = null;
      lightRay.direction = objToLight;
      lightRay.origin = rayCollInfo.hitVec;
      lightRay.origin = lightRay.hit(0.0001);
      for(int j = 0; j < renderList.size(); j++){
        RayCollInfo currRayCollInfo = renderList.get(j).intersection(lightRay);
        if(currRayCollInfo.time > 0 && currRayCollInfo.time < shadeTime && currRayCollInfo.obj!=null && currRayCollInfo.obj!=firstObj){
          shadowObj = renderList.get(j);
          shadeTime = currRayCollInfo.time;
          shadowIntersection = currRayCollInfo;
        }
      }
      if(shadowIntersection != null){
        shadowObj = shadowIntersection.obj;
        if(shadowIntersection.hitVec != null){
          dist = distance(shadowIntersection.hitVec,rayCollInfo.hitVec);
        }
      }
      PVector tempColor = new PVector();
      tempColor.x = diffuseColor.x * light.colour.x;
      tempColor.y = diffuseColor.y * light.colour.y;
      tempColor.z = diffuseColor.z * light.colour.z;
      if(distance(rayCollInfo.hitVec,lightPosition) < dist || shadowObj == null){
         finalColor.add(tempColor);
       }
    }
    
    // For Reflective surfaces. 
    if(firstObj.material.KRef > 0){
       //Create a new ray from the point where it hits.
       PVector newRayPoint = createVec(ray.origin, rayCollInfo.hitVec);
       newRayPoint.normalize();
       newRayPoint.sub(PVector.mult(rayCollInfo.normal,(2*(newRayPoint.dot(rayCollInfo.normal)))));
       newRayPoint.normalize();
       PVector newOrigin = new PVector(rayCollInfo.hitVec.x, rayCollInfo.hitVec.y, rayCollInfo.hitVec.z);
       //Move the point by a smnall amount to prevent intersection with itself       
       newOrigin.x += newRayPoint.x*0.00001; 
       newOrigin.y += newRayPoint.y*0.00001; 
       newOrigin.z += newRayPoint.z*0.00001; 
       
       Ray recursiveRay = new Ray(newOrigin, newRayPoint);
       //The recursive ray is created and the compute color function is called recursively
       PVector returnColor = computeColor(recursiveRay, firstObj);
       //Multiply the returned color by the reflectance coefficient
       returnColor.mult(firstObj.material.KRef);
       //Add the reflected colors to the final color
       finalColor.add(returnColor);
    }
       
    return finalColor;
    
  }
  else{
    return backgroundColor;
  }
  
}

void emitPhoton(Ray ray, boolean fromReflMat,  PVector photonColor){
 
  float min = 99999;
  RayCollInfo rayCollInfo = null;
  
  //Find the first intersection
  for(int i=0; i< renderList.size(); i++){
    RayCollInfo currRayCollInfo = renderList.get(i).intersection(ray);
    if(currRayCollInfo.time > 0 && currRayCollInfo.time < min){
      min = currRayCollInfo.time;
      rayCollInfo = currRayCollInfo;
    }
  }
  
  //If there was an intersection
  if(rayCollInfo != null){
    float KRef = rayCollInfo.obj.material.KRef;
    // If the material is reflective then the photon should bounce off it
    if(KRef > 0){
       PVector newRayDir = createVec(ray.origin, rayCollInfo.hitVec);
       newRayDir.normalize();
       newRayDir.sub(PVector.mult(rayCollInfo.normal,(2*(newRayDir.dot(rayCollInfo.normal)))));
       newRayDir.normalize();
       PVector newOrigin = new PVector(rayCollInfo.hitVec.x, rayCollInfo.hitVec.y, rayCollInfo.hitVec.z);
        //Move the point by 0.00001 to prevent intersection with itself
       newOrigin.x += newRayDir.x*0.00001; 
       newOrigin.y += newRayDir.y*0.00001; 
       newOrigin.z += newRayDir.z*0.00001; 
       
       Ray recursiveRay = new Ray(newOrigin, newRayDir);
       PVector photonColour = new PVector(photonColor.x*KRef, photonColor.y*KRef, photonColor.z*KRef);
       //Emit the photon recursively until it hits a diffuse material
       emitPhoton(recursiveRay,true, photonColour);
    }
    
    // If the photon reflected off a shiny surface and then hit a diffuse surface, it has to be stored
    else if(fromReflMat && KRef == 0){
      //Store photon
      photons.add_photon(new Photon(rayCollInfo.hitVec.x, rayCollInfo.hitVec.y, rayCollInfo.hitVec.z, photonColor.x/num_cast, photonColor.y/num_cast, photonColor.z/num_cast));
    }
  }
}