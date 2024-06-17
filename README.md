# ARKit

Since the introduction of ARKit by Apple, we have been dedicated to creating various augmented reality (AR) experiences leveraging ARKit, RealityKit, and SceneKit. Our primary goal is to enhance the utility of mobile devices through innovative AR experiences.

## ARKit Features:
ARKit supports a range of features, including:
* Tracking and visualizing planes
* Tracking and altering images
* Detecting images in an AR experience
* Scanning and detecting 3D objects
* Capturing Body Motion in 3D
* Tracking and Visualizing Faces
* Tracking Geographic Locations in AR
* Screen Annotations for Objects in an AR Experience
* Many other advanced capabilities

## Demonstration Features:
This demo showcases most of these ARKit features, including:
* Creating Geo-localized AR experiences on ARWorldMap
* Detecting objects and images
* Marking specific objects and create 3D renders in point cloud
* Share information locally over maintaining the ARWorld Session
* Detecting user's Sitting posture and providng info on it
* Detecting user's Standing posture along with angles
* Detecting User's face and visualizing models on it

## Specific Features in This Demo:
* Image tracking 
* Face tracking 
* Sitting posture tracking 
* Standing posture tracking
* Applying live filter on detected surface
* Save and load maps 
* Detect objects
* Environmental texturing

### Prerequisites
Before diving into the implementation details, ensure you have the following:
* Latest version of Xcode
* Latest iOS version
* Physical iPhone device (recommended: iPhone X series or newer for optimal performance)

### Body Tracking with angles detection
Body tracking is an essential feature of ARKit enabling to track a person in the physical environment and visualize their motion by applying the same body movements to a virtual character.
Alongside this we can also create our own model to mimic user's movemnets or also can use the "biped_robot" provided by Apple itself

In this demo, we will detect and analyze two types of posture:
1. Sitting posture

This demo detects the angle between the knee and spine joints, focusing on the user's sitting posture. Studies show that sitting with proper support, maintaining an angle of more than 90 degrees, reduces pressure on the spine. The demo visually updates the detected posture: a green shape indicates a healthy posture with minimal spine pressure, while a red shape indicates poor posture.

https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/6aa6ee49-1b65-43cf-b5d8-9e97b234e894

https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/522118dd-f1b0-40ab-83fb-60b31b9c15d9

2. Standing posture

This demo focuses on standing and tracking the user's movements and joint angles. A virtual skeleton, composed of cylinders (bones) and spheres (joints), mimics the user's movements. Angle calculations are performed at the joints based on the positions of adjacent joints. This feature has various applications, including exercise-related tracking and analysis.

https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/68503890-5923-4ec6-bc65-eb5ef0027a88

### Applying live filter on rectangluar surface
To apply a live filter on a detected rectangular surface, we utilize the Vision and ARKit frameworks along with a StyleTransferModel, an MLModel provided by Apple.

Here's how it works: Using ARKit's ARImageAnchor, we track an image with a rectangular shape. We then identify the rectangular surface through VNRectangleObservation, pinpointing its four corners. The detected image's pixel buffer is converted to the dimensions required by the MLModel. This processed image is passed through the MLModel, which provides the altered images to be displayed in real-time. You can see a video demonstration below.

https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/49dfeac2-188c-40b3-97a3-5dc1489591c6

### Face Traking and loading live 3d content
Tracking and visualizing faces is a crucial feature of ARKit, enabling the detection of a user's face and expressions while simultaneously mimicking these expressions using a 3D model. ARKit's face tracking capabilities open up numerous possibilities for various applications.

In this tutorial, we demonstrate some basic functionalities of face tracking, including the ability to mimic the user's facial expressions with a 3D model. 

https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/2207f3eb-2069-4567-8dce-8789bdba8b12
 
### Image recognition and tracking
Among the new developer features introduced at WWDC, image detection and tracking stands out as one of the most exciting. Imagine being able to replace and augment any static image you see with contextual information.

While image detection was introduced in previousw versions of ARKit, its functionality and maturity were somewhat limited. With the latest release, however, you can create truly amazing AR experiences. Check out the demo below to see it in action:

In this demo, we replace a static image with a GIF in real-time using image recognition and tracking.

![alt text](https://thumbs.gfycat.com/ShamelessFlimsyArcherfish-size_restricted.gif)
 
![New Image Detecttion](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/91aae733-3ae3-4f4c-96c3-6f9f45aec3aa)


## Save and load maps
ARKit introduces the revolutionary ARWorldMap, enabling persistent and multiuser AR experiences. In simple terms, ARWorldMap allows you to not only render AR experiences and objects but also to build awareness of your user's physical space. This means your app can detect and standardize real-world features. 

With these standardized features, you can place virtual content—like funny GIFs—within your application. In this tutorial, 
we will demonstrate how to create such an experience.

Let’s dive into some technical steps about how this feature works

First we are going to get the current world map from a user’s iPhone. We will save this session to get spatial awareness and initial anchors that were are going to share with another iPhone user. 

Once, you get the session and world map related anchors from the first iPhone user. The app will now use Multipeer connectivity framework to push information on a P2P network to the 2nd iPhone user. 

The second iPhone user would receive session sent over Multipeer. The 2nd iPhone user in this case would receive a notification using a receiver handler. Once the receive a notification, we can then get session data and render it in ARWorld. 

We are going to build something like this

![New AR world sharing 1 (1)](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/c5e46c3c-3888-4049-8e9d-26718c93c936)
![New AR world sharing 2 (1)](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/5f1c9404-16e1-488c-b39d-69a777ff50f4)

If you wish to get a more hands on experience with Multi user AR experiences, Apple has a demo project just for that. You can download the demo [here](https://developer.apple.com/documentation/arkit/creating_a_multiuser_ar_experience).


### Object Scanning & Detection
The new ARKit gives you the ability to scan 3D objects in the real world, creating a map of the scanned object that can be loaded when the object comes into view in the camera. 

While scanning we can get current status of scanned object and after a successful scan we can create and share a reference object which will be used to detect an object later on.

https://github.com/SimformSolutionsPvtLtd/ARKit-Prototype/assets/63225913/8cd83dd7-7a5f-4871-9870-7691f400d9b3

Similar to the ARWorldMap object, ARKit creates a savable ARReferenceObject that can be saved and loaded during another session.

 ![New Object detection](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/3553ba08-e0a2-41b7-ab4e-a668a3b72f6d)
 
### Environment Texturing
In previous versions of ARKit, 3D objects positioned in the real world lacked the ability to effectively integrate with their surroundings, often appearing artificial and disconnected. However, with the introduction of environmental texturing, these objects can now reflect their environment, enhancing their realism and sense of presence.

Here’s how it works: When a user scans a scene using ARKit, the software captures and maps the environment onto a cube map. This cube map is then applied to the 3D object, allowing it to reflect back the surrounding environment.

What makes this feature particularly advanced is Apple's use of machine learning to fill in parts of the cube map that the camera cannot capture, such as overhead lights or other scene details. This ensures that even if the entire scene isn't fully scanned, the object appears as if it naturally belongs in that space, reflecting elements that may not be directly visible.

Overall, environmental texturing significantly improves the realism and integration of AR objects by seamlessly blending them with and reflecting their real-world surroundings.
 
![New Env Texturing](https://github.com/SimformSolutionsPvtLtd/ARKit2.0-Prototype/assets/63225913/2e8bee92-267c-4a90-8608-76af83bcb886)

Apple has created a project that can be used to scan 3D objects, and can be downloaded [here](https://developer.apple.com/documentation/arkit/scanning_and_detecting_3d_objects?changes=latest_minor)
 
### Inspired
 This demo is created from Apple's ARKit sample [demo](https://developer.apple.com/documentation/arkit)
 
