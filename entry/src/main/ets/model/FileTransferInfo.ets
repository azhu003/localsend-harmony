import { FileTransferStatus, IMoveFile } from ".";

@Observed
export class FileTransferInfo implements IMoveFile {
  fileId: string = ''
  status: FileTransferStatus = FileTransferStatus.QUEUE
  progress: number = 0
  speed: number = 0
  filePath?: string
  error?: object | undefined | null

  getFilepath(): string {
    return this.filePath || ''
  }

  setNewFilepath(newFilepath: string): void {
    this.filePath = newFilepath
  }
}