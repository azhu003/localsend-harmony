export class HttpRequestError extends Error {
  status: number

  constructor(status: number, message: string = '') {
    super()
    super.message = message
    this.status = status
  }
}