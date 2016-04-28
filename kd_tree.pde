// Photon and kD-tree classes

import java.util.*;   // need this to use priority queues

int sort_axis;  // for building the kD-tree

// Photon class
public class Photon implements Comparable<Photon>{
  float[] pos;  // 3D position of photon, plus one extra value for nearest neighbor queries
  // YOU WILL WANT TO MODIFY THIS CLASS TO RECORD THE POWER OF A PHOTON
  
  float powerR;
  float powerG;
  float powerB;
  Photon (float x, float y, float z, float powerR, float powerG, float powerB) {
    pos = new float[5];  // x,y,z position, plus fourth value that is used for nearest neighbor queries
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;
    pos[3] = 0;  // distance squared, used for nearby photon queries
    this.powerR = powerR;
    this.powerG = powerG;
    this.powerB = powerB;
  }
  Photon (float x, float y, float z) {
    pos = new float[5];  // x,y,z position, plus fourth value that is used for nearest neighbor queries
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;
    pos[3] = 0;  // distance squared, used for nearby photon queries
  }

  // Compare two nodes, used in two different circumstances:
  // 1) for sorting along a given axes during kd-tree construction (sort_axis is 0, 1 or 2)
  // 2) for comparing distances when locating nearby photons (sort_axis is 3)
  public int compareTo(Photon other_photon) {
    if (this.pos[sort_axis] < other_photon.pos[sort_axis])
      return (-1);
    else if (this.pos[sort_axis] > other_photon.pos[sort_axis])
      return (1);
    else
      return (0);
  }
}

// One node of a kD-tree
class kd_node {
  Photon photon;    // one photon is stored at each split node
  int split_axis;   // which axis separates children: 0, 1 or 2 (-1 signals we are at a leaf node)
  kd_node left,right;  // child nodes
}

class kd_tree {

 kd_node root;  // root node of kd-tree
 ArrayList<Photon> photon_list;  // initial list of photons (empty after building tree)
 float max_dist2;                // squared maximum distance, for nearest neighbor search
 
 // initialize a kd-tree
 kd_tree() {
   photon_list = new ArrayList<Photon>();
 }
 
 // add a photon to the kd-tree
 void add_photon (Photon p) {
   photon_list.add (p);
 }
 
 // Build the kd-tree.  Should only be called after all of the
 // photons have been added to the initial list of photons.
 void build_tree() {
   root = build_tree (photon_list);
 }
 
// helper function to build tree -- should not be called by user
 kd_node build_tree(List<Photon> plist) {
   int i,j;
   
   kd_node node = new kd_node();
      
   // see if we should make a leaf node
   if (plist.size() == 1) {
     node.photon = plist.get(0);
     node.split_axis = -1;  // signal a leaf node by setting axis to -1
     node.left = node.right = null;
     return (node);
   }
   
   // if we get here, we need to decide which axis to split
   
   float[] mins = new float[3];
   float[] maxs = new float[3];
   
   // initialized min's and max's
   mins[0] = mins[1] = mins[2] =  1e20;
   maxs[0] = maxs[1] = maxs[2] = -1e20;
   
   // now find min and max values for each axis
   for (i = 0; i < plist.size(); i++) {
     Photon p = plist.get(i);
     for (j = 0; j < 3; j++) {
       if (p.pos[j] < mins[j]) mins[j] = p.pos[j];
       if (p.pos[j] > maxs[j]) maxs[j] = p.pos[j];
     }
   }
   
   float dx = maxs[0] - mins[0];
   float dy = maxs[1] - mins[1];
   float dz = maxs[2] - mins[2];
   
   // the split axis is the one that is longest
   
   sort_axis = -1;
   
   if (dx >= dy && dx >= dz)
     sort_axis = 0;
   else if (dy >= dx && dy >= dz)
     sort_axis = 1;
   else if (dz >= dx && dz >= dy)
     sort_axis = 2;
   else {
     println ("cannot deterine sort axis");
     exit();
   }
     
   // sort the elements according to the selected axis
   Collections.sort(plist);
   
   // determine the median element and make that this node's photon
   int split_point = plist.size() / 2;
   Photon split_photon = plist.get(split_point);
   node.photon = split_photon;
   node.split_axis = sort_axis;
   //if split point is first node, no left tree
   if (split_point == 0) {
     node.left = null;
   }
   else {
     node.left = build_tree (plist.subList(0, split_point));
   }
   //if split point is last node, no right tree
   if (split_point == plist.size()-1) {
     node.right = null;
   }
   else {
     node.right = build_tree (plist.subList(split_point+1,  plist.size()));
   }
   return (node);
 }
 
 //// draw all of the "photons" in 2D -- for use in debugging
 //void draw(kd_node n) {
 //  if (n == null)
 //    return;
 //  ellipse ((float)n.photon.pos[0], (float)n.photon.pos[1], (float)photon_radius, (float)photon_radius);
 //  if (n.left != null)
 //    draw(n.left);
 //  if (n.right != null)
 //    draw(n.right);
 //}
 
 // Find the nearby photons to a given location.
 //
 // x,y,z    - given location for finding nearby photons
 // num      - maxium number of photons to find
 // max_dist - maximum distance to search
 // returns a list of nearby photons
 ArrayList <Photon> find_near (float x, float y, float z, int num, float max_dist) {
   
   // set the maximum distance squared, which is global to this kd-tree
   max_dist2 = max_dist * max_dist;
   // create an empty list of nearest photons
   PriorityQueue<Photon> queue = new PriorityQueue<Photon>(20,Collections.reverseOrder());  // max queue
   sort_axis = 3;  // sort on distance (stored as the 4th float of a photon)
   // find several of the nearest photons
   float[] pos = new float[3];
   pos[0] = x;
   pos[1] = y;
   pos[2] = z;
   find_near_helper (pos, num, root, queue);
   
   // move the photons from the queue into the list of nearby photons to return
   ArrayList<Photon> near_list = new ArrayList<Photon>();
   do {
     near_list.add (queue.poll());
   } while (queue.size() > 0);
   
   return (near_list);
 }
 
 // help find nearby photons (should not be called by user)
 void find_near_helper (float[] pos, int num, kd_node node, PriorityQueue<Photon> queue) {
   
   Photon photon = node.photon;
   
   // maybe recurse
   int axis = node.split_axis;
   if (axis != -1) {  // see if we're at an internal node
     // calculate distance to split plane
     float delta = pos[axis] - photon.pos[axis];
     float delta2 = delta * delta;
     if (delta < 0) {
       if (node.left != null)
         find_near_helper (pos, num, node.left, queue);
       if (node.right != null && delta2 < max_dist2)
         find_near_helper (pos, num, node.right, queue);
     }
     else {
       if (node.right != null)
         find_near_helper (pos, num, node.right, queue);
       if (node.left != null && delta2 < max_dist2)
         find_near_helper (pos, num, node.left, queue);
     }
   }
   
   // examine photon stored at this current node

   float dx = pos[0] - photon.pos[0];
   float dy = pos[1] - photon.pos[1];
   float dz = pos[2] - photon.pos[2];
   float len2 = dx*dx + dy*dy + dz*dz;
   
   if (len2 < max_dist2) {
     // store distance squared in 4th float of a photon (for comparing distances)
     photon.pos[3] = len2;
     // add photon to the priority queue
     queue.add (photon);
     // keep the queue short
     if (queue.size() > num)
       queue.poll();  // delete the most distant photon
     // shrink max_dist2 if our queue is full and we've got a photon with a smaller distance
     if (queue.size() == num) {
       Photon near_photon = queue.peek();
       if (near_photon.pos[3] < max_dist2)
         max_dist2 = near_photon.pos[3];
     }
   }
 }

}