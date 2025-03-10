export interface IMoveFile {
  getFilepath(): string

  setNewFilepath(newFilepath: string): void
}

// export class SimpleMoveFile implements IMoveFile {
//   filepath: string = ''
//
//   constructor(filepath: string) {
//     this.filepath = filepath
//   }
//
//   getFilepath(): string {
//     return this.filepath
//   }
//
//   setNewFilepath(newFilepath: string): void {
//     this.filepath = newFilepath
//   }
// }