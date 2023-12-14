# Bluetoothed ARKit 2.0 with ARWorldMap!

After Apple’s introduction of ARKit 2, we have been consistently working behind to create shared-AR experiences. Our goal is to improve the utility of mobile using AR experiences. 

This demo created using ARKit 2:
* Creates Geo-localized AR experiences on ARWorldMap
* Detects objects and images
* Mark specific objects and create 3D renders in point cloud
* Share information locally over BLE (Bluetooth low energy)

## Features in this demo:
* Image tracking 
* Save and load maps 
* Detect objects
* Environmental texturing

### Prerequisites
Before we dive into the implementation details let’s take a look at the prerequisites of the course.
 
* Xcode 10 (beta or above)
* iOS 12 (beta or above)
* Physical iPhone 6S or above
 
### Image recognition and tracking
“A photo is like a thousands words” - words are fine, but, ARKit-2 turns a photo into thousands of stories. 

Among the new dev features introduced in WWDC 2018, Image detection and tracking is one of the coolest. Imagine having the capability to replace and deliver contextual information to any static image that you see.  

Image detection was introduced in ARKit 1.5, but the functionality and maturity of the framework was a bit low. But with this release, you can build amazing AR experiences. Take a look at the demo below: 

![alt text](https://thumbs.gfycat.com/ShamelessFlimsyArcherfish-size_restricted.gif)
 
* Class : AVImageDetection.swift
```sh
let configuration = ARImageTrackingConfiguration()
let warrior = ARReferenceImage(UIImage(named: "DD")!.cgImage!,orientation: CGImagePropertyOrientation.up,physicalWidth: 0.90)
configuration.trackingImages = [warrior]
configuration.maximumNumberOfTrackedImages = 1
```
you can do custom action after image detect. We have added one GIF in replace of detected image.
 
```sh
func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            let material = SCNMaterial()
            material.diffuse.contents = viewObj
            plane.materials = [material]
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
        } else {
            if isFirstTime == true{
                isFirstTime = false
            } else {
                return node
            }
            let plane = SCNPlane(width: 5, height: 5)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 1)
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = .pi
            let shipScene = SCNScene(named: "art.scnassets/Sphere.scn")!
            let shipNode = shipScene.rootNode.childNodes.first!
            shipNode.position = SCNVector3Zero
            shipNode.position.z = 0.15
            planeNode.addChildNode(shipNode)
            node.addChildNode(planeNode)
        }
        return node
    }
```
![New Image Detecttion](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/91aae733-3ae3-4f4c-96c3-6f9f45aec3aa)


## Save and load maps
ARKit 2 comes with revolutionary ARWorldMap that allows persistent and multiuser AR experiences. In simpler words, you can use ARWorldMap to not only render AR experiences and render objects, but it also builds awareness about your user’s physical space and helps your app. This means that you can detect and standardise real world features in your iOS app. 

You can then use these standardised features to place virtual content (funny GIFs anyone?) on your application. 

We are going to build something like this

![alt text](https://thumbs.gfycat.com/UnluckyOpenBug-size_restricted.gif)
Let’s dive into tech implementation.

First we are going to get the current world map from a user’s iPhone by using .getCurrentWorldMap(). We will save this session to get spatial awareness and initial anchors that were are going to share with another iPhone user. 

* Class : AVSharingWorldMapVC.swift 
```sh
sceneView.session.getCurrentWorldMap { worldMap, error in
        guard let map = worldMap
        else { print("Error: \(error!.localizedDescription)"); return }
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        else { fatalError("can't encode map") }
        self.multipeerSession.sendToAllPeers(data)
}
```
Once, you get the session and world map related anchors from the first iPhone user. The app will now use Multipeer connectivity framework to push information on a P2P network to the 2nd iPhone user. 

The code below shows how the second iPhone user would receive session sent over Multipeer. The 2nd iPhone user in this case would receive a notification using a receiver handler. Once the receive a notification, we can then get session data and render it in ARWorld. 
```sh
func receivedData(_ data: Data, from peer: MCPeerID) {
        if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(of: ARWorldMap.classForKeyedArchiver()!, from: data), let worldMap = unarchived as? ARWorldMap {
            // Run the session with the received world map.
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.initialWorldMap = worldMap
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            mapProvider = peer
        }
}
```
If you wish to get a more hands on experience with Multi user AR experiences, Apple has a demo project just for that. You can download the demo [here](https://developer.apple.com/documentation/arkit/creating_a_multiuser_ar_experience).

![New AR world sharing 1 (1)](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/c5e46c3c-3888-4049-8e9d-26718c93c936)
![New AR world sharing 2 (1)](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/5f1c9404-16e1-488c-b39d-69a777ff50f4)


### Object Scanning & Detection
The new ARKit gives you the ability to scan 3D objects in the real world, creating a map of the scanned object that can be loaded when the object comes into view in the camera. 

While scanning we can get current status of scanned object from the following delegate method
* Class : ScanObjectsVC.swift
```sh
 @objc func scanningStateChanged(_ notification: Notification)
 ```
After a successful scan we can create and share a reference object which will be used to detect an object later on.
* Class : Scan.swift
```sh
 func createReferenceObject(completionHandler creationFinished: @escaping (ARReferenceObject?) -> Void) {
        guard let boundingBox = scannedObject.boundingBox, let origin = scannedObject.origin else {
            print("Error: No bounding box or object origin present.")
            creationFinished(nil)
            return
        }
        // Extract the reference object based on the position & orientation of the bounding box.
        sceneView.session.createReferenceObject(
            transform: boundingBox.simdWorldTransform,
            center: float3(), extent: boundingBox.extent,
            completionHandler: { object, error in
                if let referenceObject = object {
                    // Adjust the object's origin with the user-provided transform.
                    self.scannedReferenceObject =
                        referenceObject.applyingTransform(origin.simdTransform)
                    self.scannedReferenceObject!.name = self.scannedObject.scanName
                    creationFinished(self.scannedReferenceObject)
                } else {
                    print("Error: Failed to create reference object. \(error!.localizedDescription)")
                    creationFinished(nil)
                }
        })
    }
 ```
https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/9c2bc288-183d-409c-b489-27c5576fcdea

Similar to the ARWorldMap object, ARKit creates a savable ARReferenceObject that can be saved and loaded during another session.
* Class : AVReadARObjectVC.swift
```sh
 let configuration = ARWorldTrackingConfiguration()
 
 // ARReferenceObject(archiveURL :...   this method used when we have  ARReferenceObject Store in local Document Directory 
 configuration.detectionObjects = Set([try ARReferenceObject(archiveURL: objectURL!)])
 
 // ARReferenceObject.referenceObjects(inGroupNamed...   this method used when we have  ARReferenceObject Store in Assest Folder
 configuration.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "", bundle: .main)!
 
 sceneView.session.run(configuration)
 ```
 When Object is recognized, this delegate method will be called.
 ```sh
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? 
 ```
 You can do You custom action in this delegate method.

 ![New Object detection](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/3553ba08-e0a2-41b7-ab4e-a668a3b72f6d)
 
### Environment Texturing
In previous versions of ARKit, 3D objects placed in the real world didn’t have the ability to gather much information about the world around them. This left objects looking unrealistic and out of place. Now, with environmental texturing, objects can reflect the world around them, giving them a greater sense of realism and place. When the user scans the scene, ARKit records and maps the environment onto a cube map. This cube map is then placed over the 3D object allowing it to reflect back the environment around it. What’s even cooler about this is that Apple is using machine learning to generate parts of the cube map that can’t be recorded by the camera, such as overhead lights or other aspects of the scene around it. This means that even if a user isn’t able to scan the entire scene, the object will still look as if it exists in that space because it can reflect objects that aren’t even directly in the scene.
 
To enable environmental texturing, we simply set the configuration’s
```sh
environmentalTexturing property to .automatic.
```
![New Env Texturing](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/2e8bee92-267c-4a90-8608-76af83bcb886)

Apple has created a project that can be used to scan 3D objects, and can be downloaded [here](https://developer.apple.com/documentation/arkit/scanning_and_detecting_3d_objects?changes=latest_minor)
 
### Inspired
 This demo is created from Apple's ARKit 2 sample [demo](https://developer.apple.com/documentation/arkit/swiftshot_creating_a_game_for_augmented_reality)
 
