// src/shrink.ts: a photo made no larger than a phone's screen can show, before anything keeps it.
import { ImageManipulator, SaveFormat } from "expo-image-manipulator";

export const LONGEST = 1600; // pixels on the longer side: sharp on any phone, a fifth of a camera's photo

export async function shrink(uri: string, width: number, height: number): Promise<string> {
  if (Math.max(width, height) <= LONGEST) return uri;
  const size = width >= height ? { width: LONGEST } : { height: LONGEST };
  const image = await ImageManipulator.manipulate(uri).resize(size).renderAsync();
  const saved = await image.saveAsync({ compress: 0.7, format: SaveFormat.JPEG });
  return saved.uri;
}
