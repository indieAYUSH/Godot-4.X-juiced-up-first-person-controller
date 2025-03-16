# PLAYER_MOVEMENT

A versatile 3D player controller script for Godot that delivers smooth and immersive first-person movement. This controller supports a variety of movement mechanics including walking, sprinting, crouching, jumping, and procedural head bobbing, while managing player states and animations.

## Features

- **Smooth Movement:**  
  Uses input interpolation (lerping) for natural movement and directional transitions.
  
- **Dynamic State Management:**  
  Manages player states (Idle, Walking, Sprinting, Crouching, In Air) to trigger corresponding animations and visual effects.

- **Camera Effects:**  
  Dynamically adjusts the camera's field-of-view (FOV) during sprinting and crouching to enhance immersion.

- **Procedural Head Bobbing:**  
  Implements both vertical and horizontal head bobbing to simulate natural head movement during motion.

- **Collision Handling:**  
  Switches between standing and crouched collision shapes for accurate physics interactions and obstacle detection.

- **Integrated Animations:**  
  Triggers animations such as jump, landing, and roll based on movement states and landing impact.

- **Debug Information:**  
  Provides real-time debug displays for player speed and state to assist in testing and fine-tuning.

## Getting Started

1. **Setup:**
   - Import the `PLAYER_MOVEMENT.gd` script into your Godot project.
   - Create your player scene with the required nodes (e.g., camera, head, collision shapes, animation player).

2. **Configure Input Actions:**
   - Ensure the following input actions are defined in your project settings:
     - `left`, `right`, `forward`, `backward`
     - `jump`
     - `crouch`
     - `sprint`

3. **Customize:**
   - Adjust the exported variables (e.g., speeds, FOV values, head bobbing parameters) to suit your desired gameplay experience.

## Usage

Attach the `PLAYER_MOVEMENT.gd` script to your player character node (which should extend `CharacterBody3D`). The controller will automatically:
- Capture the mouse for first-person control.
- Process input-based movement.
- Manage state-specific animations and visual effects.

## Contributing

Contributions, improvements, and suggestions are welcome! Feel free to fork the repository, make your changes, and submit a pull request. If you encounter any issues or have ideas for enhancements, please open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
