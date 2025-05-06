import pygame
import math

# Fixed-point arithmetic constants
Q = 8
SCALE = 1 << Q
MAX_DEPTH = 16 * SCALE

# Fixed-point utility functions
def to_fixed(value):
    return int(value * SCALE)

def from_fixed(value):
    return value / SCALE

def fixed_mul(a, b):
    return (a * b) >> Q

def fixed_div(a, b):
    return (a << Q) // b

# Initialize map and player settings
MAP = [
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1]
]

WIDTH, HEIGHT = 800, 400
FOV = to_fixed(3.14159 / 3)  # Fixed-point FOV
RAYS = 80
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GREEN = (0, 255, 0)
RED = (255, 0, 0)
GRAY = (100, 100, 100)

player_x, player_y = to_fixed(3.5), to_fixed(3.5)
player_angle = 0

LUT_SIZE = 1024
PI2 = to_fixed(6.28318)

# Precompute LUTs for sin and cos in fixed-point
sin_lut = [to_fixed(math.sin(2 * math.pi * i / LUT_SIZE)) for i in range(LUT_SIZE)]
cos_lut = [to_fixed(math.cos(2 * math.pi * i / LUT_SIZE)) for i in range(LUT_SIZE)]

def sin_approx(angle):
    index = ((angle % PI2) * LUT_SIZE // PI2) % LUT_SIZE
    return sin_lut[index]

def cos_approx(angle):
    index = ((angle % PI2) * LUT_SIZE // PI2) % LUT_SIZE
    return cos_lut[index]

pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
clock = pygame.time.Clock()

def handle_input():
    global player_x, player_y, player_angle
    keys = pygame.key.get_pressed()
    speed = to_fixed(0.1)
    rot_speed = to_fixed(0.05)
    
    # Print the maximum values for player_x, player_y, and player_angle
    max_player_x = to_fixed(len(MAP[0]) - 1)
    max_player_y = to_fixed(len(MAP) - 1)
    max_player_angle = PI2 - 1

    print(f"Max player_x: {max_player_x}, Max player_y: {max_player_y}, Max player_angle: {max_player_angle}")
    print(f"Max player_x (float): {from_fixed(max_player_x)}, Max player_y (float): {from_fixed(max_player_y)}, Max player_angle (float): {from_fixed(max_player_angle)}")
    
    print(f"player_x: {player_x}, player_y: {player_y}, player_angle: {player_angle}")
    print(f"player_x: {from_fixed(player_x)}, player_y: {from_fixed(player_y)}, player_angle: {player_angle}")
    print(f" rot_speed: {rot_speed}, speed: {speed}")

    if keys[pygame.K_UP]:
        player_x += fixed_mul(cos_approx(player_angle), speed)
        player_y += fixed_mul(sin_approx(player_angle), speed)
    if keys[pygame.K_DOWN]:
        player_x -= fixed_mul(cos_approx(player_angle), speed)
        player_y -= fixed_mul(sin_approx(player_angle), speed)

    if keys[pygame.K_LEFT]:
        player_angle -= rot_speed
    if keys[pygame.K_RIGHT]:
        player_angle += rot_speed

def cast_rays():
    delta_angle = fixed_div(FOV, to_fixed(RAYS))
    ray_angle = player_angle - (FOV >> 1)
    texture_width = WIDTH // RAYS
    raycast_height = int(HEIGHT * 0.8)  # Upper 80% of the window
    for ray in range(RAYS):
        sin_a = sin_approx(ray_angle)
        cos_a = cos_approx(ray_angle)

        distance = 0
        while distance < MAX_DEPTH:
            distance += to_fixed(0.01)
            x = from_fixed(player_x + fixed_mul(distance, cos_a))
            y = from_fixed(player_y + fixed_mul(distance, sin_a))
            if MAP[int(y)][int(x)] == 1:
                break

        wall_height = int(raycast_height / from_fixed(fixed_mul(distance, cos_approx(ray_angle - player_angle))))
        color = 255 - min(255, int(from_fixed(distance) * 20))

        # Draw vertical line for smoother walls
        start_x = ray * texture_width
        for i in range(texture_width):
            pygame.draw.line(screen, (color, color, color), (start_x + i, raycast_height // 2 - wall_height // 2), (start_x + i, raycast_height // 2 + wall_height // 2))

        ray_angle += delta_angle

def draw_map():
    map_height = int(HEIGHT * 0.2)  # Bottom 20% of the window
    map_width = WIDTH
    cell_size = min(map_height // len(MAP), map_width // len(MAP[0]))
    offset_y = HEIGHT - map_height  # Start drawing from the bottom part of the window

    for y, row in enumerate(MAP):
        for x, cell in enumerate(row):
            color = BLACK if cell == 0 else WHITE
            pygame.draw.rect(screen, color, (x * cell_size, offset_y + y * cell_size, cell_size, cell_size))
            pygame.draw.rect(screen, GRAY, (x * cell_size, offset_y + y * cell_size, cell_size, cell_size), 1)

    player_pos = (int(from_fixed(player_x) * cell_size), int(offset_y + from_fixed(player_y) * cell_size))
    pygame.draw.circle(screen, RED, player_pos, 5)

    start_angle = player_angle - (FOV >> 1)
    for i in range(RAYS):
        angle = start_angle + i * fixed_div(FOV, to_fixed(RAYS))
        end_x = int(player_pos[0] + from_fixed(fixed_mul(cos_approx(angle), to_fixed(100))))
        end_y = int(player_pos[1] + from_fixed(fixed_mul(sin_approx(angle), to_fixed(100))))

        pygame.draw.line(screen, GREEN, player_pos, (end_x, end_y))

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            pygame.quit()
            exit()

    screen.fill((0, 0, 0))
    handle_input()
    cast_rays()
    draw_map()

    pygame.display.flip()
    clock.tick(60)
